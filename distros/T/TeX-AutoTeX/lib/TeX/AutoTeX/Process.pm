package TeX::AutoTeX::Process;

#
# $Id: Process.pm,v 1.14.2.7 2011/02/03 03:57:38 thorstens Exp $
# $Revision: 1.14.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Process.pm,v $
#
# $Date: 2011/02/03 03:57:38 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp;

our ($VERSION) = '$Revision: 1.14.2.7 $' =~ m{ \$Revision: \s+ (\S+) }x;

use TeX::AutoTeX::Config qw($AUTOTEX_TIMEOUT $DIRECTIVE_FILE);
use TeX::AutoTeX::Fileset;
use TeX::AutoTeX::File;

sub new {
  my $class = shift;
  my $self = {
	      log         => undef,
	      fileset     => undef,
	      stampref    => [],
	      use_stamp   => 1,
	      hlink_stamp => 1,
	      temp_dir    => undef,
	      branch      => undef,
	      dvi_flags   => [],
	      made_pdf    => [],
	      nohypertex  => undef,
	      warnings    => {},
	      decryption_key => undef,
	      tex_env_path   => undef,
	      @_
	     };

  # Sanity checks...
  croak 'No log configuration supplied.' unless defined $self->{log};
  croak 'Missing site configuration.'
    unless (defined $self->{temp_dir}
	    and defined $self->{branch}
	    and defined $self->{tex_env_path});
  if (!$self->{fileset}) {
    $self->{fileset} = TeX::AutoTeX::Fileset->new(
						  log => $self->{log},
						  dir => $self->{temp_dir},
						 );
  }
  bless $self, $class;
  return $self;
}

sub go {
  my $self = shift;

  eval {
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)}; #make %ENV safer, see camel
    local $SIG{ALRM} = sub {
      croak "AutoTeX process timed out after ${AUTOTEX_TIMEOUT}s (" . localtime(), q{)};
    };
    alarm $AUTOTEX_TIMEOUT;
    umask oct 2;
    setpgrp;
    $self->process_files();
    alarm 0; # Cancel the alarm if process_files() returns before $AUTOTEX_TIMEOUT
    1;
  } or do {
    local $SIG{TERM} = 'IGNORE';
    kill TERM => -$$;
  };
  alarm 0;   # Cancel the alarm if process_files() died.
  return $@; # true on eval error
}

sub process_files {
  my $self = shift;

  $self->clean_times();
  $self->parse_readme();
  $self->process_of_type('TYPE_ENCRYPTED');
  my $log = $self->{log};
  my $tmpdir = $self->{temp_dir};
  # list files, and build a hash of tex files and assign processing priorities
  my $highest_pri = 0;
  my %priority_value;  # stores priority values of all tex-type files
  my @unknowns = ();   # names of files with unknown types
  foreach my $fileobj ($self->file_list()) {
    my $filename = $fileobj->{filename};
    my $filetype = $fileobj->filetype_name();
    if ( $filetype =~ /(compressed|TAR\sarchive|MULTI_PART_MIME|UUencoded)/i ) {
      $log->error("Package contains '$filename' which is of type '$filetype'. This file should be removed or marked ignore.");
      exit 121;
    }
    next if ( -d "$tmpdir/$filename" #TS there shouldn't be any directories in self->file_list()
	      || $filename eq q{.}   #   shouldn't happen
	      || $filename eq q{..}  #   shouldn't happen
	    );
    unless ($filename =~ /auto_gen(?:_ps)?\.log/) {
      $log->verbose(" <$filename>\t is of type '$filetype'.");
      if ($filetype eq 'unknown'){
	push @unknowns, $filename;
      }
    }
    $priority_value{$filename} = $fileobj->assign_tex_priority();
    if ($priority_value{$filename} > $highest_pri) {
      $highest_pri = $priority_value{$filename};
    }
  }

  my %process_fail_time = (); # times of attempted processing of failures
  unless ($highest_pri) {
    $log->verbose('No tex files present, going to hope we can process as a postscript or dvi only package.');
  } else {
    # We go through the list of files sorted by priorities in reverse and
    # lexicographic order (as of perl 5.6 sort is stable, so two succeeding
    # sorts retain order) attempting to process them until successful.
    my @fileobjects =
      sort {$priority_value{$b->{filename}} <=> $priority_value{$a->{filename}}}
	sort {$a->{filename} cmp $b->{filename}}
	  grep {$priority_value{$_->{filename}} > 0}
	    $self->file_list(); #TS: note that this re-scans cwd
    my $successful = 0;
    my $start = time;
    foreach my $fileobj (@fileobjects) {
      my $filename = $fileobj->{filename};
      if (! -e "$tmpdir/$filename") {
	$log->verbose("'$filename' already used and removed, no longer in the processing queue.");
	next;
      }
      if (!$successful || (stat "$tmpdir/$filename")[8] < $start) { #atime
	$log->verbose(" ~~~~~~~~~~~ Processing file '$filename'");
	if ($fileobj->process($self)){ # returns true if unsuccessful
	  $process_fail_time{$filename} = time;
	} else { # processing was successful
	  if ($self->{branch} eq '3' || $self->{branch} =~ m{texlive/}) { # check for generated PDF
	    (my $pdffile = $filename) =~ s/(?:\.[^.]*)?$/.pdf/; #TS: note pathologic case "^.something$"
	    if (-s "$tmpdir/$pdffile" && (stat(_))[9] >= $start) { # mtime
	      push @{$self->{made_pdf}}, $pdffile;
	      if (my $stampref = $self->get_stamp()) {
		$log->verbose("now stamping pdf file '$pdffile' with stamp '$stampref->[0]'");
		require TeX::AutoTeX::StampPDF;
		TeX::AutoTeX::StampPDF::stamp_pdf("$tmpdir/$pdffile", $stampref);
		$log->verbose('stamped pdf file');
	      }
	    }
	  }
	  $successful++;
	}
      }

      if ( -e "$tmpdir/missfont.log" ){
	$log->error('missfont.log present.');
	exit 123;
      }
    }
    if (!$successful) {
      $log->error('Unable to sucessfully process tex files.');
      exit 125;
    } else {
      my $junk_warning = q{};
      foreach my $unknown (@unknowns) {
	my $atime = (stat "$tmpdir/$unknown")[8];  # undef if no longer present
	if ($atime and $atime < $start){  # file hasn't been read since start of process
	  $junk_warning .= "<$unknown> unrecognized by FileGuess:\n"
	    . ( -T "$tmpdir/$unknown" ? `head "$tmpdir/$unknown"` : 'not an ASCII text file' )
	      . "\n--------------------------------------\n";
	}
      }
      foreach my $filename (keys %process_fail_time){
	my $atime = (stat "$tmpdir/$filename")[8];
	if ($atime <= $process_fail_time{$filename}){
	  # file hasn't been read since failed attempt at processing it
	  # TS: note that atime = process_fail_time does not conclusively indicate anything
	  #     would have to re-set atime after process failure before continuing,
	  #     because second granularity is not fine enough.
	  $junk_warning .= "<$filename> appears to be tex-type, but was neither included nor processable:\n"
	    . ( -T "$tmpdir/$filename" ? `head "$tmpdir/$filename"` : 'not an ASCII text file' )
	      . "\n--------------------------------------\n";
	}
      }
      if ($junk_warning) {
	$log->verbose("Junk file warnings!\n\n--------------------------------------\n$junk_warning");
	$self->{warnings}{junk_warning} = $junk_warning;
      }
    }
  }
  $self->process_of_type('TYPE_DVI');
  if ( -e "$tmpdir/missfont.log" ){
    $log->error('missfont.log present.');
    exit 127;
  }
  if (@{$self->{made_pdf}} > 1) {
    my $combinedfile = 'xxxpdfpages';
    if (-e "$tmpdir/$combinedfile.tex" || -e "$tmpdir/$combinedfile.pdf") {
      $combinedfile = "xxxpdfpages_$$";
    }
    open my $PDFPAGES, '>', "$tmpdir/$combinedfile.tex" ||
      $log->error("couldn't open $combinedfile.tex for writing: $!");
    print {$PDFPAGES} "\\pdfoutput=1\n\\documentclass{article}\n\\usepackage{pdfpages}\n\\begin{document}\n",
      join(q{}, map { "\\includepdf[pages=-]{$_}\n" } @{$self->{made_pdf}}),
	"\\end{document}\n";
    close $PDFPAGES || $log->verbose("error closing $combinedfile.tex: $!");
    $log->verbose('creating a combined PDF file out of multiple PDF documents');
    $self->{made_pdf} = [];
    if ($self->{fileset}->new_File("$combinedfile.tex")->process($self)) {
      $log->error('failed to create combined PDF file.');
    } else {
      $self->{made_pdf}->[0] = "$combinedfile.pdf";
    }
  }
  return;
}

sub clean_times {
  my $self = shift;

  opendir(my $DIR, $self->{temp_dir})
    || $self->{log}->error("Could not read directory '$self->{temp_dir}'.");
  my $now = time;
  my $count = map {utime($now, $now, "$self->{temp_dir}/$_")
		     || $self->{log}->verbose("Couldn't touch $_: $!");}
    map {m/^(.*)$/}
      grep {$_ ne q{.} && $_ ne q{..}}
	readdir $DIR;
  ### $self->{log}->verbose("Touched $count files and directories.");
  closedir $DIR;
  return 0;
}

sub process_of_type {
  my $self = shift;
  my @types = @_;

  my @fileobjects = $self->file_list();

  foreach my $fileobj (@fileobjects) {
    my $t = $fileobj->type();
    foreach my $type (@types) {
      if ($t eq $type) {
	if ($t eq 'TYPE_DVI') {
	  $fileobj->set_dvi_flags($self->dvi_flags_tostring());
	}
	$fileobj->process($self);
      }
    }
  }
  return 0;
}

sub file_list {
  my $self = shift;
  opendir(my $DIR, $self->{temp_dir})
    || $self->{log}->error('Could not read directory.');
  my @fileobjects = map {$self->{fileset}->new_File($_)}
    grep {-f "$self->{temp_dir}/$_"} # no (sub-)directories, symlinks, etc
      readdir $DIR;
  closedir $DIR;
  return @fileobjects;
}

sub parse_readme {
  my $self = shift;
  return unless -e "$self->{temp_dir}/$DIRECTIVE_FILE";
  open(my $README, '<', "$self->{temp_dir}/$DIRECTIVE_FILE")
    || $self->{log}->error("Couldn't open $DIRECTIVE_FILE");
  while (my $line = <$README>) {
    next if $line =~ /^[#%]/;  # allow shell-style and tex-style comments
    chomp $line;
    $line =~ s/\s+$//;
    $line =~ s/^\s+//;
    my ($token, $type) = split /\s+/, $line, 2;
    if (!defined $token) {
      $self->{log}->verbose("$DIRECTIVE_FILE PARSER: I don't get this: $line");
      next;
    }
    if ($token eq 'nohypertex') {
      $self->{nohypertex} = 1;
      $self->{log}->verbose('nohypertex: switching off hyperlinks');
      next;
    }
    if ($token eq 'nostamp') {
      $self->{use_stamp} = 0;
      $self->{log}->verbose('nostamp: will not stamp PostScript or PDF');
      next;
    }
    if (!defined $type) {
      $self->{log}->verbose("$DIRECTIVE_FILE PARSER: I don't get this: '$line'");
      next;
    }

    my $file = $self->{fileset}->new_File($token);

    my %flagtypes = (
		     landscape    => "landscape: will use landscape mode for '$token'\n",
		     keepcomments => "dvips flag '-K0' will be used for '$token'\n",
		     toplevelfile => "toplevelfile: will use '$token' as parent\n" ,
		    );


    if (my $message = $flagtypes{$type}) {
      $file->set_flag($type);
      $self->{log}->verbose($message);
      next;
    }

    if ($type eq 'fontmap') {
      if ($token =~ /^\+?([a-z]+\.map)$/i) {
	$self->add_dvi_flag("-u +./$1");
	$self->{log}->verbose("dvips flag '-u +./$1' will be used");
      }
      $file->type_override('include');
      next;
    }
    # if type didn't trigger any other action
    $file->type_override($type);
  }
  close($README) || $self->{log}->verbose("warning: couldn't close directive file: $!");
  return;
}

sub set_dvi_flags {
  my $self = shift;
  @{$self->{dvi_flags}} = @_;
}

sub dvi_flags_tostring {
  my $self = shift;
  return join q{ }, @{$self->{dvi_flags}};
}

sub add_dvi_flag {
  my $self = shift;
  my $argstring = shift || carp 'no arguments provided to add_dvi_flag()';
  push @{$self->{dvi_flags}}, $argstring;
}

sub set_use_stamp {
  my $self = shift;
  $self->{use_stamp} = shift;
}

sub toggle_hlink_stamp {
  my $self = shift;
  $self->{hlink_stamp} = 1^$self->{hlink_stamp};
}

sub get_stamp {
  my $self = shift;
  if ($self->{use_stamp}) {
    return $self->{stampref};
  }
  return;
}

sub get_warning {
  my ($self, $type) = @_;
  return($self->{warnings}{$type});
}

1;

__END__

=for stopwords tex Sep chroot dvips nohypertex pdfs pdf readme Accessors PostScript Accessor arxiv.org www-admin Schwander perlartistic

=head1 NAME

TeX::AutoTeX::Process - orchestrate the system calls for tex, dvips, etc.

=head1 DESCRIPTION

The Process object is instantiated to oversee processing after a
a temporary directory has been create containing the paper source
inside. Processing of individual files is handled by TeX::AutoTeX::File.

=head1 HISTORY

 AutoTeX automatic TeX processing system
 Copyright (c) 1994-2006 arXiv.org and contributors

 AutoTeX is supplied under the GNU Public License and comes
 with ABSOLUTELY NO WARRANTY; see COPYING for more details.

 AutoTeX is an automatic TeX processing system designed to
 process TeX/LaTeX/AMSTeX/etc source code of papers submitted
 to the arXiv.org (nee xxx.lanl.gov) e-print archive. The
 portable part of this code has been extracted and is made
 available in the hope that it will be useful to other projects
 and that the input of others will benefit arXiv.org.

 Code developed and contributed to by Tanmoy Bhattacharya, Rob
 Hartill, Mark Doyle, Thorsten Schwander, and Simeon Warner.
 Refactored to separate generic code from arXiv.org specific code
 by Stephen Marsh, Michael Fromerth, and Simeon Warner 2005/2006.

 Major cleanups and algorithmic improvements/corrections by
 Thorsten Schwander 2006 - 2011

=head1 SUBROUTINES/METHODS

=head2 new() -- Structure of Process Object

=over 4

=item go, do the processing

=item log, TeX::AutoTeX::Log object

=item temp_dir, the temp directory we create to muck about in branch, the tex
branch we will be using

=item stamp, the stamp, e.g. 'arXiv:hep-th/9901001 v1 10 Sep 2001' to be
added to the processed file

=item use_stamp, a flag, determines whether stamp will be added

=item tex_env_path, location of binaries within chroot

=item decryption_key, key to be used to decrypt encrypted files

=item dvi_flags, the flags that should be passed to dvips

=item add_dvi_flag, push the provided parameter onto the array of dvips
options

=item dvi_flags_tostring, convert the array of parameters for dvips to a
string suitable for the command-line

=item nohypertex, a flag, prevents hyperlinking

=item made_pdf, ref to array which stores the names of the pdfs generated by
pdf(la)tex, initialized empty

=item warnings, a hash in which warnings are stored during processing that
may then be accessed via get_warning()

=back

 Call this to process the paper
 Creates a new Process object.
 Call as TeX::AutoTex::Process->('log'=>$log,'temp_dir'=>...);

 returns undef if processing was successful, true (an error string) otherwise

=head2 process_files()

Process the files in the current directory

If a pdf is generated, stores its filename(s) in @{$self->{made_pdf}} so that
the calling code can then act appropriately.

=head2 clean_times()

Sets the timestamps on all the files to the current time.

=head2 process_of_type(@types)

Process files if there are ones of the list of types passed to this subroutine.

=head2 file_list()

Returns an array of File objects representing the files currently present in
the working directory. The directory contents changes with each processing
stage, so this is called repeatedly to get a fresh view of the directory.

=head2 parse_readme()

Parses the readme file.

=head2 set_dvi_flags(@flags)

Accessors for process specific dvi_flags

=head2 set_use_stamp(BOOLEAN)

Allows one to change whether or not the stamp will be added to output

=head2 toggle_hlink_stamp()

Toggle whether or not the stamp will be hyperlinked

=head2 get_stamp()

Returns the stamp that should be placed on PostScript files, or undefined if
we aren't to use a stamp on this paper.

=head2 get_warning($type)

Accessor method for any warnings that have been written into the
$self->{warnings} hash during processing. The argument specifies which type
of warning. (Could be extended to return all types of warning if $type not
specified.)

=head1 BUGS AND LIMITATIONS

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

See history above. Current maintainer: Thorsten Schwander for
L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
