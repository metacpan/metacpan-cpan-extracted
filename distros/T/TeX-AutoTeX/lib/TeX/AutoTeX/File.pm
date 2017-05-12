package TeX::AutoTeX::File;

#
# $Id: File.pm,v 1.36.2.5 2011/01/22 04:53:23 thorstens Exp $
# $Revision: 1.36.2.5 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/File.pm,v $
#
# $Date: 2011/01/22 04:53:23 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp;

our ($VERSION) = '$Revision: 1.36.2.5 $' =~ m{ \$Revision: \s+ (\S+) }x;

use Scalar::Util qw(weaken);

use TeX::AutoTeX::Exception;
use TeX::AutoTeX::HyperTeX;
use TeX::AutoTeX::PostScript;
use TeX::AutoTeX::Config qw(
			     $CRYPT
			     $DVIPS
			     $TEXCHR
			     $DIRECTIVE_FILE
			     %TEX_BINARIES
			     $TEX_PATH
			  );

use arXiv::FileGuess qw(guess_file_type is_tex_type type_name);

sub new {
  my ($class, $fileset, $filename) = @_;

  my $self = {
	      flags     => {},
	      dvi_flags => q{},
	      fileset   => $fileset,
	      binaries  => {%TEX_BINARIES},
	      untaint_regexp => qr/[^&\s;]+/,
	     };
  if ($filename =~ /^($self->{untaint_regexp})$/ && $filename !~ /^\./) {
    $self->{filename} = $1; # untaint
  } else {
    throw TeX::AutoTeX::InvNameException("Invalid filename: '$filename'.");
  }
  weaken $self->{fileset};
  bless $self, $class;
}

sub filename {
  my $self = shift;
  return $self->{filename};
}

sub type {
  my $self = shift;
  # we cache the value
  $self->{type} = $self->determine_type() if !defined $self->{type};
  return $self->{type};
}

sub determine_type {
  my $self = shift;

  return 'TYPE_README' if $self->{filename} eq $DIRECTIVE_FILE;
  my $fullname = "$self->{fileset}->{dir}/$self->{filename}";
  return 'TYPE_DIRECTORY' if -d $fullname;
  my ($type, $texformat, $error) = guess_file_type($fullname);
  $self->{fileset}->{log}->error($error) if $error;
  $self->{tex_format} = lc $texformat if defined $texformat;
  return $type;
}

sub filetype_name {
  my $self = shift;
  return arXiv::FileGuess::type_name($self->type());
}

sub type_is_tex {
  my $self = shift;
  return arXiv::FileGuess::is_tex_type($self->type());
}

sub assign_tex_priority {
  # TS: 12/2010
  # trying to solve the dependency tree in general is equivalent to the halting problem
  # these are heuristics that work in practice on the material arXiv deals with,
  # but they are also easily fooled

  my $self = shift;
  if ($self->{flags}->{toplevelfile}){
    return 4;
  }
  # FileGuess incorrectly identifies some files (especially style files)
  # as tex files that aren't.
  if (!$self->type_is_tex()
      || $self->{filename} eq 'auto_gen_ps.log'
      || $self->{filename} =~ /\.(?:sty|st|cls)$/i){
    return 0;
  }
  # take advantage of logic in arXiv::FileGuess
  if (0 <= index $self->{type}, 'priority2') {
    return 1;
  } elsif (0 <= index $self->{type}, 'priority') {
    return 2;
  } elsif ('_MAC' eq substr $self->{type}, -4) {
    return 3;
  }
  # rate based on filename and contents
  open(my $CURRENTFILE, '<', "$self->{fileset}->{dir}/$self->{filename}")
    || $self->{fileset}->{log}->error("Could not open '$self->{filename}': $!");
  my $docstycls = 0;
  # grant higher priority to files that end with tex-related extension
  $docstycls++ if $self->{filename} =~ /\.(?:la)?tex$/i;
  while (<$CURRENTFILE>) {
    if (/^\s*\\document(?:style|class)/){
      $docstycls++;
      last;
    }
  }
  while (<$CURRENTFILE>) {
    if (/^\s*\\begin\s*\{\s*document\s*\}/){
      $docstycls++;
      last;
    }
  }
  close $CURRENTFILE or $self->{fileset}->{log}->verbose("couldn't close file: $!");
  return $docstycls;
}

sub type_override {
  my ($self, $type) = @_;
  if (my $override = $self->{fileset}->override($type)) {
    $self->{type} = $override;
    $self->{fileset}->{log}->verbose(<<"EOM");
Directive file has overriden $self->{filename}'s type to be '$type' ($override).
EOM
    return;
  }
  $self->{fileset}->{log}->verbose(<<"EOW");
Directive file wanted to override $self->{filename}'s type as '$type',
but this type has no override.
EOW
  return 1;
}

sub set_flag {
  my ($self, $flag) = @_;
  return $self->{flags}->{$flag} = 1;
}

sub check_flag {
  my ($self, $flag) = @_;
  return exists $self->{flags}->{$flag};
}

sub set_dvi_flags {
  my $self = shift;
  return $self->{dvi_flags} = shift;
}

sub get_dvi_flags {
  my $self = shift;
  return $self->{dvi_flags};
}

sub process {
  my ($self, $process) = @_;

  my $result;
  if ($self->type_is_tex()) {
    $result = $self->process_tex($process);
  } elsif ($self->type() eq 'TYPE_ENCRYPTED') {
    $result = $self->process_encrypted($process);
  } elsif ($self->type() eq 'TYPE_DVI') {
    $result = $self->process_dvitype($process);
  }
  return $result;
}

sub process_tex {
  my ($self, $process) = @_;

  my $log = $self->{fileset}->{log};
  my $dir = $self->{fileset}->{dir};

  my $tex_passes = 4;
  my ($new_type, $dont_hyper, $try_amslplain) =
    TeX::AutoTeX::HyperTeX::copy_source_from_hyper(
						   $self->type(),
						   $self->{filename},
						   $dir,
						   $log,
						   $self->{fileset}->{local_hyper_transform}
						  );
  if ($self->{type} ne $new_type) {
    $log->verbose(<<"EOM");
Changing type from '$self->{type}' to '$new_type' on recommendation of
TeX::AutoTeX::HyperTeX::copy_source_from_hyper.
EOM
    $self->{type} = $new_type;
  }

  my $try_hyper = $dont_hyper ? 0 : !$process->{nohypertex};
  $log->verbose('Will not attempt to use hypertex.') unless $try_hyper;

  # initalize @to_try with the different formats in the order we want to try them
  my @to_try;
  if ($process->{branch} eq '3' || $process->{branch} =~ m{texlive/}) {
    if ($self->type() eq 'TYPE_LATEX' || $self->type() eq 'TYPE_LATEX2e') {
      @to_try = map {$try_hyper ? ("h$_", $_) : $_ } qw(latex pdflatex tex);
    } elsif ($self->type() eq 'TYPE_PDFLATEX') {
      @to_try = map {$try_hyper ? ("h$_", $_) : $_ } qw(pdflatex tex);
    } else {
      # we always try tex, in case of amslplain or such
      @to_try = $try_hyper ? qw(htex tex) : 'tex';
      # we always try latex, not just tex, because sometimes latex papers are misidentified as tex
      push @to_try, $try_hyper ? qw(hlatex latex) : 'latex';
    }
  } elsif ($process->{branch} eq '2') {
    # deal with legacy stuff
    if (exists $self->{tex_format}) {
      if ($self->{tex_format} eq 'bigtex') {
	$log->verbose('Using bigtex');
	$self->{binaries}->{HTEX} = $self->{binaries}->{TEX} = $self->{binaries}->{BIGTEX};
      } elsif ($self->{tex_format} eq 'biglatex') {
	$log->verbose('Using biglatex');
	$self->{binaries}->{HLATEX2E} = $self->{binaries}->{LATEX2E} = $self->{binaries}->{BIGLATEX};
      } elsif ($self->{tex_format} eq 'latex209') {
	@to_try = $try_hyper? qw(hlatex209 latex209) : 'latex209';
      } elsif ($self->{tex_format} eq 'latex') {
	@to_try = $try_hyper ? qw(hlatex2e hlatex209 latex2e latex209) : qw(latex2e latex209);
      }
    } elsif ($self->type() eq 'TYPE_LATEX') {
      @to_try = $try_hyper ? qw(hlatex2e hlatex209 latex2e latex209) : qw(latex2e latex209);
    } elsif ($self->type() eq 'TYPE_LATEX2e') {
      @to_try = $try_hyper ? qw(hlatex2e latex2e) : 'latex2e';
    }
    # under some circumstances, what looked like latex files are actually
    # tex files with amsart.
    if ($try_amslplain) {
      push @to_try, $try_hyper ? qw(hamslplain amslplain) : 'amslplain';
    }
    if (@to_try == 0) {
      # we always try latex, not just tex, because sometimes latex papers are misidentified as tex
      @to_try = map { $try_hyper ? ("h$_", $_) : $_ } qw(tex latex2e);
    } else {
      push @to_try, $try_hyper ? qw(htex tex) : 'tex';
    }
  } else {
    $log->verbose('unknown TeX branch');
  }

  my $failed = 0;
  my %written = ();
  foreach my $tex_type (@to_try) {
    if ('h' eq substr $tex_type, 0, 1) {
      $self->swap_source('hyper');
    } else {
      $self->swap_source('nohyper');
    }

    my ($stime, $program, $old_format);
    # get the appropriate program name from the variables set in TeX::AutoTeX::Config
    if ($tex_type =~ /amslplain/) {
      $old_format = $self->{tex_format};
      $self->{tex_format} = 'amslplain';
      if ('h' eq substr $tex_type, 0, 1) {
	$program = $self->{binaries}->{HTEX};
      } else {
	$program = $self->{binaries}->{TEX};
      }
    } else {
      $program = $self->{binaries}->{uc($tex_type)};
    }
    if (! $self->{fileset}->{utime}) {# set mtime and atime on all (non-dot-)files in CWD back 10 seconds
      my $setbacktime = time() - 10;
      ###	 {#TS: extensive logging
      ###	       my @allfiles = glob("*");
      ###	       local $" = "]\n\t[";
      ###	       $log->verbose("current file contents:\n\t[@allfiles]");
      ###	 }
      opendir my $CDIR, $dir or $log->verbose("opening directory '$dir' for reading failed: $!");
      my $numfiles = utime $setbacktime, $setbacktime,
	map { "$dir/$_" }
	  map { /^($self->{untaint_regexp})$/o }
	    grep { !/^\./ && -f "$dir/$_" }
	      readdir $CDIR;
      closedir $CDIR or $log->verbose("closing directory $dir failed: $!");
      #TS Note:
      # if we don't reset (a|m)time each time the loop processes a new file
      # the .with_hyper and .without_hyper files will not have proper stat
      # values and will be removed. if we globally reset (a|m)time, things go
      # awry with inclusion checking. Therefore make sure to reset utime in
      # swap_source for hyper files in HyperTeX.pm.
      $self->{fileset}->{utime}++;
    }
    $stime = time;
    $failed = $self->run_tex_attempt($program, $tex_passes, $process, $stime, \%written, $tex_type);
    if ($tex_type =~ /amslplain/) {
      $self->{tex_format} = $old_format;
    }
    $self->clean_aux_files($stime);
    if (!$failed) {
      my $logfile = $self->basename() . '.log';
      unlink "$dir/$logfile" or
	$log->error("Could not remove file '$logfile'.");
      last;
    }
  }
  if ($failed) {
    $log->verbose("We failed utterly to process the TeX file '$self->{filename}'");
  }
  # ensure that no copies of the tex file are left behind
  unlink map {"$dir/$self->{filename}.$_"} qw(with_hyper without_hyper);
  return $failed;
}

sub process_encrypted {
  my ($self, $process) = @_;

  my $log = $self->{fileset}->{log};
  my $dir = $self->{fileset}->{dir};
  my $file = $self->{filename};

  $log->verbose( "Decrypting file '$file'");
  my $newfile = $file;
  if ('.cry' ne lc substr $newfile, -4, 4, q{}) {
    # throw exception
    $log->error("filename '$file' does not end in '.cry'.");
  }

  # arXiv specific
  my $key = $process->{decryption_key};
  $log->verbose("running: '$CRYPT $newfile $key'");

  # ensure proper path so that correct programs decry and cipher are found
  if (index($ENV{PATH}, $TEX_PATH) != 0) {
    local $ENV{PATH} = "$TEX_PATH/bin:" . $ENV{PATH};
  }
  my $fullname = "$dir/$newfile";
  # The following two lines are necessary to get decry to work
  {
    open my $OUTFH, '>', $fullname; close $OUTFH;
    chmod oct(666), $fullname;
  }
  $log->verbose("path is: '$ENV{PATH}'");
  my $response = `$CRYPT $fullname $key` || "[no response, exit code $?]";
  if ($?) {
    $log->error("$CRYPT error response: '$response'");
  }
  if (! -T $fullname || -z _) {
    $log->error("'$file' didn't decrypt to a text file.");
  }
  unlink "$dir/$file" or $log->error("unable to remove '$file': $!");
  return;
}

sub process_dvitype {
  my ($self, $process) = @_;

  my $log = $self->{fileset}->{log};
  my $dir = $self->{fileset}->{dir};
  my $file = $self->{filename};

  my $dvi_flags = $process->{branch} =~ m{texlive/}? '-R2' : '-R';
  $dvi_flags .= " $self->{dvi_flags}" if $self->{dvi_flags};
  $dvi_flags .= ' -t landscape' if $self->{flags}->{landscape};
  $dvi_flags .= $self->{flags}->{keepcomments}? ' -K0' : ' -K1';

  my $response;
  my $setenv = qq{export HOME=/tmp @{[$ENV{TEXMFCNF}? "TEXMFCNF=$ENV{TEXMFCNF}": q{}]} PATH=$process->{tex_env_path}};
  my $crdir = substr $dir, length $TEX_PATH;
  while (1) {
    $log->verbose(" ~~~~~~~~~~~ Processing file '$file'");
    my $dvipscommand = qq#$TEXCHR $TEX_PATH "($setenv; cd $crdir && $DVIPS $dvi_flags -z '$file' -o )" 2>&1#;
    $log->verbose('Running: ' . substr $dvipscommand, length "$TEXCHR $TEX_PATH ");
    my $dvipstime = time;
    $response = `$dvipscommand`;
    last if !$?;
    $log->verbose("$DVIPS $dvi_flags -z produced an error: $?\nResponse was $response\nRetrying without '-z'");
    if (-e "$dir/head.tmp" && -e "$dir/body.tmp") {
      unlink "$dir/head.tmp", "$dir/body.tmp";
      $log->verbose('removed dvips leftover head.tmp and body.tmp');
    }
    # dvips -z may have core-dumped. remove only newly generated core file(s)
    if (my @corefiles = glob "$dir/core\.[0-9]*") {
      @corefiles =
	map { m/(.*)/ }
	  grep { m{^$dir/core\.\d+$} && (stat "$dir/$_")[9] >= $dvipstime }
	    @corefiles;
      if (@corefiles) {
	unlink @corefiles;
	$log->verbose("removed one or more core files: @corefiles");
      }
    }
    $dvipscommand = qq#$TEXCHR $TEX_PATH "($setenv; cd $crdir && $DVIPS $dvi_flags '$file' -o )" 2>&1#;
    $log->verbose('Running: ' . substr $dvipscommand, length "$TEXCHR $TEX_PATH ");
    $response = `$dvipscommand`;
    last if !$?;
    $log->verbose("$DVIPS $dvi_flags produced an error: $?\nResponse was $response.");
    $log->error('Failed to produce postscript from dvi.');
  }
  $log->verbose("dvi(h)ps said ...\n$response.");

  my %commondvipsheaders;
  @commondvipsheaders{qw(
			  tex.pro
			  texc.pro
			  texps.pro
			  hps.pro
			  special.pro
			  color.pro
			  finclude.pro
			  alt-rule.pro
			  head.tmp
			  body.tmp
			  8r.enc
			  texnansi.enc
		       )} = ();

  while ($response =~ m{<(?:\.//?)*([^><\n]+)>}g) {
    my $included = $1;
    if ($included !~ m{^/}){
      if (-e "$dir/$included") {
	$self->{fileset}->new_File($included)->set_flag('used_by_dvips');
	$log->verbose("'$included' no longer required ... it's in the postscript file.");
      } elsif (!(exists $commondvipsheaders{$included} || '.pfb' eq substr $included, -4)) {
	$log->verbose("'$included' was apparently included, but cannot be deleted, because it cannot be found in cwd.");
      }
    }
  }
  my $psfile = $file;
  substr $psfile, -3, 3, 'ps';
  # Change %%Title if wanted
  if (my $stampref = $process->get_stamp()) {
    TeX::AutoTeX::PostScript::fix_ps_title(
					   $psfile,
					   $dir,
					   $stampref->[0],
					   $log
					  );
    TeX::AutoTeX::PostScript::stamp_postscript(
					       $psfile,
					       $dir,
					       $stampref,
					       $log
					      );
  }
  $self->{fileset}->new_File($psfile)->set_flag('main_postscript');

  return;
}

sub slurp_log {
  my $self = shift;
  my $log = $self->basename() . '.log';

  open(my $LOG, '<', "$self->{fileset}->{dir}/$log")
    || $self->{fileset}->{log}->error("Could not open log file '$log' produced by (la)tex.");
  local $/ = undef;
  my $log_contents = <$LOG>;
  close $LOG;
  return \$log_contents;
}

sub clean_aux_files {
  my ($self, $stime) = @_;

  opendir(my $WORKING_DIR, $self->{fileset}->{dir})
    || $self->{fileset}->{log}->error("Can't open processing directory: $!");
  if (my @auxfiles =
      grep { /\.aux$/ && -f "$self->{fileset}->{dir}/$_" && (stat(_))[9] >= $stime }
      readdir $WORKING_DIR) {
    my $numauxfiles = unlink(
			     map { "$self->{fileset}->{dir}/$_" }
			     map { m/(.*)/ }
			     @auxfiles
			    )
      || $self->{fileset}->{log}->error("Could not remove one of the auxfiles: @auxfiles.");
    $self->{fileset}->{log}->verbose("unlinked $numauxfiles '.aux' files");
  }
  closedir($WORKING_DIR);
  return;
}

sub swap_source {
  my ($self, $hyper) = @_;

  my $file  = $self->{filename};
  my $dir = $self->{fileset}->{dir};

  #  remove aux files if any
  my $basename = $self->basename();
  foreach my $auxfile (grep {-e "$dir/$_"} map {"$basename.$_"} qw(aux lot lof toc)) {
      unlink "$dir/$auxfile" or $self->{fileset}->{log}->error("failed to remove '$auxfile'.");
      $self->{fileset}->{log}->verbose("removed aux file '$auxfile'");
  }

  # remove the existing file to be processed, then link the
  # with/without hyper version to it
  unlink "$dir/$file" or $self->{fileset}->{log}->error("failed to remove '$file'.");

  # note that (hard-)linking does not change atime or mtime
  if ($hyper eq 'hyper') {
    link "$dir/$file.with_hyper", "$dir/$file"
      or $self->{fileset}->{log}->verbose("failed to rename '$file'");
  } else {
    link "$dir/$file.without_hyper", "$dir/$file"
      or $self->{fileset}->{log}->verbose("failed to rename '$file'");
  }
  return;
}

sub run_tex_attempt {
  my $self = shift;
  my ($program, $tex_passes, $process, $stime, $written, $tex_type) = @_;

  my $log = $self->{fileset}->{log};

  if (!defined $TEXCHR) {
    throw TeX::AutoTeX::TexChrException('TEXCHR not set.');
  }
  if ($process->{branch} eq '2' && !defined $ENV{TEXMFCNF}) {
    throw TeX::AutoTeX::TexMFCnfException('TEXMFCNF not set for /2 branch.');
  }
  #TS: find the source of STDIN input to be used. this was historically used for
  # macros which required user input -- e.g. big or little (b/l)
  my $latex_input = $self->basename() . '.inp';
  my $feeder = -e "$self->{fileset}->{dir}/$latex_input" ? qq{'$latex_input'} : '/dev/null';

  my $tex_format = $self->{tex_format} || q{};
  my $escaped_tex_format = q{};

  if (!$tex_format && $tex_type eq 'htex') {
    $tex_format = 'htex';
  }
  if ($tex_format !~ /209$/ &&  $tex_type =~ /209/) {
    $tex_format .= '209';
  }
  if ($tex_format =~ /^latex209/ && $program =~ /^h/) {
    $tex_format = 'hlatex209';
  }
  if ($tex_format){
    ## TS: FIXME
    ## static lookup table instead of (convoluted) regexp. should go into
    ## TeX::AutoTeX::Config?  here is the list of all formats available in
    ## arXiv's tex installation. For texlive 2009 and newer arXiv doesn't
    ## build custom formats any longer.
    my %known_formats;
    @{$known_formats{'3'}}{qw(
			     amstex
			     htex
			     tex
			     latex
			     biglatex
			     pdfamstex
			     pdflatex
			     pdftex
			  )} = ();

    @{$known_formats{'2'}}{qw(
			     amslatex1.1
			     amslplain
			     amstex
			     biglatex
			     bigtex
			     cp-aa
			     hlatex209
			     hlatex2e
			     hlatex
			     hlplain
			     hplain
			     htex
			     latex209
			     latex2e
			     latex
			     lplain
			     plain
			     tex
			     texsis
			  )} = ();

    if (exists $known_formats{$process->{branch}}{$tex_format}) {
      $log->verbose("Using format file $tex_format");
      $escaped_tex_format = q{&} . $tex_format;
      # escape (&) in $tex_format and remove double quotes
      # TS: where would those come from after the lookup table replaced older code?
      $escaped_tex_format =~ s/&/\\\&/g;
      $escaped_tex_format =~ s/"//g; # "
    } else {
      $log->verbose("'$tex_format' is not a valid TeX format; will ignore.");
    }
  }

  my $setenv = qq{export HOME=/tmp @{[$ENV{TEXMFCNF}? "TEXMFCNF=$ENV{TEXMFCNF}": q{}]} PATH=$process->{tex_env_path}};
  $log->verbose(qq{TEXMFCNF is @{[$ENV{TEXMFCNF}? "set to: '$ENV{TEXMFCNF}'": 'unset.']}});
  my $crdir = substr $self->{fileset}->{dir}, length $TEX_PATH;
  my $runtexcommand = qq#$TEXCHR $TEX_PATH "($setenv; cd $crdir && $program $escaped_tex_format '$self->{filename}' < $feeder)" 2>&1#;

  my $passes = 0;
  my $rerun = 0;
  my $extra_pass = 0;
  my $xfontcreate = 0;
  my $lastlog_ref;
  my $failed;

  my @ORDER = qw(first second third fourth fifth sixth seventh);

 PASSES:
  while ($passes < $tex_passes) {
    $log->verbose(" ~~~~~~~~~~~ Running $tex_type for the $ORDER[$passes] time ~~~~~~~~");
    $log->verbose('Running: ' . substr $runtexcommand, length "$TEXCHR $TEX_PATH ");
    my $out = `$runtexcommand`;
    $log->verbose($out);
    $lastlog_ref = $self->slurp_log();

    # TS: This is due to peculiarities of feynmf and similar dynamical font
    # creation. If we get an error exit status from latex then we need to
    # check for new font files and possibly rerun. Only do this once, in
    # case the non-zero exit status is due to some problem other than
    # font-creation and persistent, otherwise this could loop indefinitely.
    if ($?) {
      if (!$xfontcreate && $self->extra_fontcreation_pass($stime)) {
	$xfontcreate++;
	redo PASSES;
      } else {
	#the message below is slightly misleading because $program for
	#latex2e hyper/nohyper is the same.
	$log->verbose("$program '$self->{filename}' failed.");
	$self->trash_tex_aux_files($stime, $written);
	my $dvi = $self->basename() . '.dvi';
	if (-e "$self->{fileset}->{dir}/$dvi") {
	  $log->verbose("removing leftover dvi file '$dvi'");
	  unlink "$self->{fileset}->{dir}/$dvi" or
	    $log->verbose("Could not remove file '$dvi'.");
	}
	$failed = 1;
	last;
      }
    }

    if ($passes == 0 &&	($tex_type eq 'hlatex2e' ||
			 $tex_type eq 'latex2e' ||
			 $tex_type =~ /h?pdflatex/o)) {
      if (0 <= index ${$lastlog_ref}, 'LaTeX Warning: Writing file `') {
	while(${$lastlog_ref} =~ /LaTeX Warning: Writing file \`([^']*)\'\./g) { # ')){
	  $written->{$1}++;
	}
      }
    }

    # TS: added $tex_format b/c otherwise &amslplain will only be processed twice
    if ($tex_type =~ /latex/i || $tex_format) {
      if (0 <= index(${$lastlog_ref}, q{Label(s) may have changed. Rerun}) ||
	  0 <= index(${$lastlog_ref}, q{Warning: Citation(s) may have changed.}) ||
	  0 <= index(${$lastlog_ref}, q{Table widths have changed. Rerun LaTeX.}) ||
	  0 <= index(${$lastlog_ref}, q{Rerun to get citations correct.})
	 ) {
	$rerun = 1;
      } else {
	$rerun = $self->extra_pass($stime);
      }
    } else {
      $rerun = 0;
    }
    # TS: this seems to be contraproductive to the $tex_passes=4 for &amslplain
    # and possibly others
    last unless $rerun || $passes == 0;
    $passes++;
  } # End of while ($passes < $tex_passes)

  if ($passes == $tex_passes && $rerun) {
    $log->verbose("WARNING: Reached max number of passes, possibly failed to get CROSS-REFERENCES right.");
  }
  $self->trash_tex_aux_files($stime, $written);
  return $failed;
}

sub extra_pass {
  my ($self, $younger_than) = @_;

  opendir my $CDIR, $self->{fileset}->{dir};
  my $tocloflot =
    grep {/\.(?:toc|lof|lot)$/ && -f "$self->{fileset}->{dir}/$_" && ((stat(_))[9] >= $younger_than)}
      readdir $CDIR;
  closedir $CDIR;
  if ($tocloflot) {
    #TS:  here a toc/lof/lot will always lead to max number of runs
    #     this is more robust than attempting to keep it to minimum
    #     in particular since a long toc etc. can lead to a shift between
    #     3rd and 4th pass without any indication of such in the log

    $self->{fileset}->{log}->verbose('LaTeX wrote a .toc, .lof, or .lot file - running extra passes');
    return 1;
  }
  return 0;
}

sub extra_fontcreation_pass {
  my ($self, $younger_than) = @_;

  opendir my $CDIR, $self->{fileset}->{dir};
  my $mftfm =
    grep {/\.(?:mf|tfm)$/ && -f "$self->{fileset}->{dir}/$_" && ((stat(_))[9] >= $younger_than)}
      readdir $CDIR;
  closedir $CDIR;
  if ($mftfm) {
    $self->{fileset}->{log}->verbose(<<"EOM");
LaTeX wrote a .tfm or .mf file -- this indicates feynmf or similar dynamic font generation.
    Ignoring non-zero exit status and starting over retaining the new font files!
EOM
    return 1;
  }
  return 0;
}

sub trash_tex_aux_files {
  my $self = shift;
  my ($younger_than, $written) = @_;

  my $dir = $self->{fileset}->{dir};
  opendir(my $TEMPDIR, $dir);
  my @files =
      map {/^(.*)$/}                      # untaint
	grep {!/^\./                      # no dot files
		&& !/\.(mf|log)$/         # need metafont files and associated log for labels
		  && -f "$dir/$_"         # recently modified files only
		    && (stat(_))[9] >= $younger_than}
	  readdir $TEMPDIR;
  closedir $TEMPDIR;

  foreach my $file (@files) {
    # Warn about files written by latex but still delete them.
    # We do not want people to include figures by dumping them out
    # from the tex file using the LaTeX2e filecontents environment.
    # Simeon-21Jul2000
    if ($written->{$file}) {
      $self->{fileset}->{log}->verbose("TeX wrote out '$file', going to delete it as we don't permit filecontents inclusion of figures.");
      delete $written->{$file};
    }
    my $fmt = $self->{fileset}->new_File($file)->type();
    next if grep {$fmt eq 'TYPE_' . $_} qw(DVI POSTSCRIPT PDF);

    my $age = (stat("$dir/$file"))[9]; #TS FIXME: expensive stat for logging
    $self->{fileset}->{log}->verbose("Removing (La)TeX AUX file called '$file' ($age >= $younger_than)");
    unlink "$dir/$file"
      or $self->{fileset}->{log}->error("failed to remove '$file': $!");
  }
  return 0;
}

#######################################################################
# basename()
# takes filename from AutoTeX::File object, removes its extension if it has
# one, caches and returns result.
# a special case is a filename ending in '.'. in this
# context, it should also be removed.
# substr/rindex is 3x faster than regexp s/\.[^.]*$//;

sub basename {
  my $self = shift;
  if (!defined $self->{basename}) {
    if (0 < index $self->{filename}, q{.}) {
      $self->{basename} = substr $self->{filename}, 0, rindex($self->{filename}, q{.});
    } else {
      $self->{basename} = $self->{filename};
    }
  }
  return $self->{basename};
}

1;

__END__

=for stopwords AutoTeX filename tex dvips behaviour harvmac toplevelfile readme unlinks nohyper hypertex arxiv.org www-admin Schwander perlartistic

=head1 NAME

TeX::AutoTeX::File

=head1 DESCRIPTION

The File object stores information on files processed by AutoTeX,
and is also invoked to handle the actual processing for these files.
Most of the TeX processing code is located here.

=head2 Structure of File Object

=over 4

=item filename: the name of the file

=item type: the TYPE, of the form TYPE_FAILED and such

=item tex_format: if a tex file, stores the format.

=item flags: a hash table for keeping track of various flags

=item dvi_flags: the flags that should be passed to dvips

=back

=head1 METHODS

=head2 new

Creates a new File object. Call as TeX::AutoTex::File->new($fileset, $filename)
Logging is inherited from the TeX::AutoTeX::Fileset object $fileset.

To get cache behaviour, instantiate instead through the TeX::AutoTeX::Fileset
context as $fileset->new_File($filename).

=head2 set_dvi_flags()

setter for file specific dvi_flags

=head2 get_dvi_flags()

getter for file specific dvi_flags

=head2 type()

returns a file's type, in a form like 'TYPE_FAILED' or such

=head2 filename()

returns the filename attribute

=head2 determine_type()

determines the file type and returns it. Will also store the tex format if
necessary.

=head2 filetype_name()

returns an English description of the type.

=head2 type_is_tex()

determines if the type is in the list of tex types.

=head2 assign_tex_priority()

Returns a number, the higher it is the more likely this file is to be a top
level tex file.  Possible return values:

=over 4

=item 0: non-(la)tex files and non-standalone (la)tex files.

=item 1: 'priority 2' tex files

=item 2: 'priority 1' tex files

=item 3: harvmac tex files and standalone latex files

=item 4: files marked "toplevelfile" in $DIRECTIVE_FILE

=back

=head2 type_override()

Call to override type. Intended to be used only be readme parser.

=head2 process()

processes this file. Call as $file->process($instance_of_TeX::AutoTeX::Process).
if this is a tex file, returns 0 on non-failure.

=head2 process_tex

gets called by process, the subroutine above, when a tex file is encountered
returns the log file, so process can check for file inclusion

=head2 process_dvitype

gets called when a DVI file is encounterd. attempts conversion of DVI to
PostScript

=head2 process_encrypted

this is a stub which is not functional without external helper programs. Some of the source files at arXiv are encrypted to protect their contents from close inspection by third parties.

=head2 slurp_log()

reads the log file produced by running tex/whatever, returns reference to a
scalar holding the entire log file

=head2 clean_aux_files($start_time)

unlinks all '.aux' files newer than the process start time, remove from cache if present

=head2 swap_source($hyper)

links in place the appropriate source, either what copy_source_from_hyper
generated for use with nohyper, or a version that can be used with hypertex

=head2 run_tex_attempt(@args)

runs the actual tex/latex/whatever program. Will do multiple passes and such

=head2 extra_pass($start_time)

determines whether latex has created files that would imply an extra pass
needs to be done.

=head2 extra_fontcreation_pass($start_time)

checks to see if font generation took place. If so, causes run_tex_attempt to
cycle again.

=head2 trash_tex_aux_files($start_time, \%created_files)

deletes tex aux files after tex has been run

=head2 check_flag

simple boolean check on whether a particular flag is set

=head2 set_flag

set a flag for the given name to true

=head2 basename

return the name of a file without the extension (if any)

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
