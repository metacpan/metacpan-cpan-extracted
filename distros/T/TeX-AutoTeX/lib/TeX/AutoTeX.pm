package TeX::AutoTeX;

#
# $Id: AutoTeX.pm,v 1.20.2.7 2011/01/27 18:56:29 thorstens Exp $
# $Revision: 1.20.2.7 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX.pm,v $
#
# $Date: 2011/01/27 18:56:29 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp;

# our ($VERSION) = '$Revision: 1.20.2.7 $' =~ m{ \$Revision: \s+ (\S+) }x;
our $VERSION = 'v0.906.0';

use TeX::AutoTeX::Config qw(
			     $AUTOTEX_ENV_PATH
			     $DEFAULTPSRESOLUTION
			     $DEFAULT_BRANCH
			     $DEFAULT_TEX_BIN_PATH
			  );
use TeX::AutoTeX::Fileset;
use TeX::AutoTeX::File;
use TeX::AutoTeX::Log;
use TeX::AutoTeX::Process;
use TeX::AutoTeX::Mail;

use parent qw(Class::Accessor::Fast);
__PACKAGE__->follow_best_practice();
__PACKAGE__->mk_accessors(
			  qw(
			      workdir
			      branch
			      use_stamp
			      stampref
			      log
			      verbose
			      send_email
			      dvips_paper_type
			      dvips_resolution
			      dvips_printer
			      dvips_mapfile
			      output_format
			      is_pdftex
			      tex_env_path
			   )
			 );

sub new {
  my $class = shift;
  my $self = {
	      workdir     => undef,
	      branch      => undef,
	      use_stamp   => 1,
	      stampref    => undef,
	      log         => undef,
	      send_email  => 0,
	      verbose     => undef,
	      dvips_paper_type => undef,
	      dvips_resolution => $DEFAULTPSRESOLUTION,
	      dvips_printer    => undef,
	      dvips_mapfile    => undef,
	      @_,
	     };
  if (!defined $self->{workdir}) {
    croak 'no directory holding the unpacked source material defined';
  }
  if ($self->{workdir} ne 'will be derived from paper id'
      && (stat $self->{workdir})[2] != oct(40777)
      && (stat(_))[2] != oct(40775)) {
    croak "workdir '$self->{workdir}' is not a directory or doesn't have mode 0777 or 0775";
  }

  bless $self, $class;
}

sub process {
  my $self = shift;

  local ($?, $!, $@);

  if (!$self->{branch}) { # use the latest branch, unless specified otherwise
    $self->{branch} = $DEFAULT_BRANCH;
    $self->{tex_env_path} = $DEFAULT_TEX_BIN_PATH;
    local $ENV{TEXMFCNF} = q{}; # prevent inadvertent problems due to user settings
  }
  if (ref $self->{log} ne 'TeX::AutoTeX::Log') {
    $self->{log} = TeX::AutoTeX::Log->new(
					  dir     => $self->{workdir},
					  verbose => $self->{verbose},
					  dupefh  => $self->{verbose} ? \*STDOUT : undef,
					 );
  }

  my $p = $self->{process} =
    TeX::AutoTeX::Process->new(
			       log      => $self->{log},
			       fileset  => $self->{fileset},
			       temp_dir => $self->{workdir},
			       branch   => $self->{branch},
			       stampref => $self->{stampref},
			       use_stamp      => $self->{use_stamp},
			       decryption_key => $self->{decryption_key},
			       tex_env_path   => $self->{tex_env_path}? $self->{tex_env_path}
			                                              : "/$self->{branch}/bin:/bin",
			      );

  if ($self->__combine_dvips_flags()) {
    $p->set_dvi_flags(@{$self->{dvi_flags}})
  }

  if (ref $self->{stampref} ne 'ARRAY') {
    $p->{use_stamp} = 0;
  }

  local $ENV{PATH} = $AUTOTEX_ENV_PATH; # also untaints path

  if ($p->{error} = $p->go()) {
    $self->{log}->verbose("AutoTeX returned error: $p->{error}");
    # optionally send failure notification email to admin
    if ($self->{send_email}) {
      $self->email();
      }
    return;
  }
  if (@{$p->{made_pdf}}) {
    $self->{log}->verbose('PDFTEX paper, check "'
			  . ($self->{paper} ? $self->{paper} : $self->{workdir})
			  . qq{".\n});
    $self->set_is_pdftex(1);
  }

  $self->{log}->verbose("All done.\n");
  return 1;
}

sub __combine_dvips_flags {
  my $self = shift;
  $self->{dvi_flags} = [];
  if ($self->{dvips_paper_type} && $self->{dvips_paper_type} =~ /^([a-z0-9]+)$/i) {
    push @{$self->{dvi_flags}}, "-t $1";
  }
  if (defined $self->{dvips_printer}) {
    if ($self->{dvips_printer} =~ /(?:type1|pdf)/i) {
      push @{$self->{dvi_flags}}, '-P type1';
      $self->{output_format} = 'fInm';
    } elsif ($self->{dvips_printer} eq 'pk') {
      # TS: new for texlive 12/2009
      push @{$self->{dvi_flags}}, '-P pk';
    }
  }
  if ($self->{dvips_resolution} && $self->{dvips_resolution} =~ /^([346]00)$/) {
    if ($1 != $DEFAULTPSRESOLUTION) {
      push @{$self->{dvi_flags}}, "-D $1";
      $self->{output_format} ||= "d$1"; # don't overwrite 'fInm'
    }
  }
  if ($self->{dvips_mapfile} && $self->{dvips_mapfile} =~ /^\+?([a-z]+\.map)$/i) {
    push @{$self->{dvi_flags}}, "-u +$1";
  }
  return wantarray ? @{$self->{dvi_flags}} : scalar @{$self->{dvi_flags}};
}

sub email {
  my $self = shift;

  my $dvips_options = $self->{process}->dvi_flags_tostring();

  my $mailer = TeX::AutoTeX::Mail->new($self->{workdir});
  if (my $msg = $mailer->send_failure("Failure for $self->{workdir}", <<"EOM")
 $self->{workdir} failed autotex,
 dvips run with options '$dvips_options'.

 $self->{process}->{error}
EOM
     ) {
    $self->{log}->verbose("send_failure error: $msg");
  }
  return;
}

1;

__END__

=begin stopwords

arXiv arXiv's arxiv.org CVS STDOUT  TeXLive Schwander perlartistic
DVI PostScript PDF dpi pdf metafont dvips papertype hyperref.cfg geometry.cfg .cfg config
logfile pre- hashref workdir chroot tex texmf texmf.cnf stampref fontmap config.ps

=end stopwords

=head1 NAME

TeX::AutoTeX - automated processing of (La-)TeX sources

=head1 WARNING

TeX::AutoTeX::process will modify, overwrite, and delete files in the
specified directory. It is assumed that directory is a temporary working
directory and that the sources were copied from elsewhere for
processing. Make sure you have copies of your files before attempting to run
this module.

=head1 VERSION

see CVS revision number

=head1 SYNOPSIS

 use TeX::AutoTeX;
 my $t = TeX::AutoTeX->new( workdir => '/some/temp/directory',);
 $t->process or warn 'processing failed';

A more elaborate example

 use TeX::AutoTeX;

 my $t = TeX::AutoTeX->new( workdir => '/some/temp/directory', verbose => 1,);
 $t->{log} = TeX::AutoTeX::Log->new(
 				   dir     => $t->{workdir},
 				   verbose => $t->{verbose},
 				   dupefh  => $t->{verbose} ? \*STDOUT : undef,
 				  );
 }
 $t->{log}->open_logfile();
 $t->set_dvips_resolution(600);
 $t->set_stampref(['foobar paper', 'http://example.com/my/paper.pdf']);
 if ($t->process()) {
   print "Success\n"
 } else {
   print "Processing failed: inspect $t->{workdir}/auto_gen_ps.log\n";
 }

=head1 DESCRIPTION

This module is the basis for arXiv's automatic (La-)TeX processing. The
normal use is to point it at a directory with an assortment of files in it,
and the B<process> method will attempt to generated DVI, PostScript, or PDF from
the input based on heuristics which have been developed and employed by arXiv
for many years. The resulting file(s) remain in the same directory. It is up
to the calling process to pre- or post-process the directory contents as
required.

No particular naming conventions or other requirements are imposed on the
source material, and sub-directories are permitted. The module attempts to
determine processing order and input format based on file characteristics and
heuristics and generally does not require any user input.

Note that arXiv does not allow execution of external programs from C<TeX> or
C<dvips> (paranoid setting in texmf.cnf), and that neither C<makeindex> or
C<bibtex> or similar intermediate programs are run. These are deliberate
choices. Consequently this module doesn't provide that functionality either.

=head1 METHODS

The main purpose of C<TeX::AutoTeX> is to create an instance for a given
source directory, set attributes relevant for processing and then call
C<process> to do the work.

=head2 new

C<< new( workdir => <directory_name>, ) >> instantiates a C<TeX::AutoTeX> object
with default settings. The single required argument is the C<workdir>, which
is the directory in which the source material can be found and processed.

All other attributes outlined below can be set, i.e. defaults can be
overwritten, via a hashref passed to C<new>.

=head2 process

This is the main method of a TeX::AutoTeX object. It will start the
processing and perform the format conversion according to the object's
attributes. C<process> itself does not take any parameters.

C<process> returns C<1> on success and C<undef> on failure.

=head2 email

sends email about a failure to the recipient for such messages configured in
$TeX::AutoTeX::Config::MAIL_FAILURES_ADDRESS

=head1 OPTIONS

These are simple (get|set)_accessors for attributes and flags

=over 4

=item workdir

get/set the directory in which the source material will be processed.

Note that processing typically is done in a B<chroot> jail, and the
processing directory should be inside that jail.

=item branch

get/set the branch, e.g. the TeX installation, input tree(s), etc. This
allows to select between various TeX installations or texmf input trees. It
is a path based selection of the top level directory and associated texmf.cnf
file.  At arXiv we have e.g. teTeX/2/texmf-2003 teTeX/2/texmf-2004
teTeX/3/texmf-2006. This method should be overloaded with custom selection
settings to reflect local directory hierarchies. Something along the lines of

  if (!$self->{branch}) { # use the latest branch, unless specified otherwise
    $self->{branch} = '3';
    $ENV{TEXMFCNF} = '/3/texmf/web2c';
    $self->{tex_env_path} =  '/3/bin:/bin';
  }

The example above reflects arXiv's use of PATH settings relative to a chroot
root directory.

=item (get|set)_tex_env_path

get or set the $ENV{PATH} value for system calls, defaults to
C</$branch/bin:/bin>. This allows for branch based path variations like
/2/bin, /3/amd64/bin, /texlive/x86_64/bin depending on available local tex
trees

=item use_stamp

get/set flag to enable or disable stamping of the first page. This is a
simple on/off switch. (default 1)

=item stampref

get/set the array ref holding the text of the stamp and the URL to hyperlink
on the first page. At arXiv the values are derived from the item identifier
and local link structure.

=item log

get/set the TeX::AutoTeX::Log object for logging of warnings/errors. The
default is to instantiate a TeX::AutoTeX::Log object with the default logfile,
B<auto_gen_ps.log>, and if set B<verbose> logging to STDOUT.

=item verbose

get/set flag to enable verbose logging to the logfile specified in the
C<TeX::AutoTeX::Log> object and STDOUT. This is a simple on/off
switch. (default 0)

=item send_email

get/set flag to send email alerts about processing problems to addresses
specified in C<TeX::AutoTeX::Config>. This is a simple on/off
switch. (default 0)

=item dvips_paper_type

get/set the dvips -t command line flag for papertype selection. The main use
of this flag is the "landscape" option, since other document layout decisions
should be taken in the source.  arXiv in particular distinguishes between US
letter size paper as the default latex and dvips option on North American
sites, and A4 paper on all other sites. This affects macro packages, etc, via
.cfg files (hyperref.cfg, geometry.cfg) or explicit modification, and dvips'
global config.ps.

=item dvips_resolution

get/set the target resolution (dpi) for dvips (-D command line option of
dvips), valid options are 300, 400, 600. (default 600)

=item dvips_printer

get/set the dvips printer type (-P command line option of dvips), relevant
for font creation and selection. (default none, valid choices type1, pdf). The
default metafont mode and associated resolution are configured in the TeX
installation. The main use of this option is to generate PostScript with
type1 fonts for PDF generation. (default none)

=item dvips_mapfile

get/set the name of a custom fontmap. If the sources contain private font
files and associated macros, this option can be used to pass an additional
font map file to dvips via the -u dvips command line option, so that dvips
can resolve those font references (default none)

=item output_format

get/set the output format. This is typically derived from other dvips flags,
in particular resolution and printer option and allows calling applications
to distinguish between various types of generated PostScript, e.g. 300 dpi
bitmap, 600 dpi bitmap, PostScript with outline (type1) fonts, uncompressed
PostScript or Postscript for a particular paper type (A4, letter, landscape)
(default none)

=back

=head1 EXIT STATUS

The main method, B<process> returns C<1> on success and C<undef> if there was
a processing error. The log file will have more information on the error in
this case.

In addition there may be fatal errors in system calls etc.. These will C<croak>.

=head1 DIAGNOSTICS

Enable verbose logging for lots of informative messages, and look at the log file
(default C<auto_gen_ps.log>)

=head1 CONFIGURATION AND ENVIRONMENT

Most of the configuration is taken from C<TeX::AutoTeX::Config>. Influencing
the TeX process via environment variables is not encouraged.

C<TeX::AutoTeX::Config> must be customized and adapted to local requirements
before use.

=head1 DEPENDENCIES

C<Class::Accessor::Fast>

This module relies on access to a complete TeX installation. A recent B<TeXLive>
distribution should be sufficient to get started, however in the scholarly
publication realm a lot of additional macro packages from publishers and
societies may need to be added to a local C<texmf> tree.

C<TeX::AutoTeX::Config> holds all of the necessary configuration and
customization. This module will not work without proper settings in the
config file.

C<arXiv::FileGuess> is required for contents based file type
determination. This could be mostly substituted for by one of C<File::Type>
C<File::MimeInfo::Magic> or C<File::LibMagic>.

=head1 BUGS AND LIMITATIONS

Let us know L<http://arxiv.org/help/contact>

=head1 HISTORY

 AutoTeX automatic TeX processing system
 Copyright (C) 1994-2006 arXiv.org and contributors

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

=head1 AUTHOR

Thorsten Schwander for L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
