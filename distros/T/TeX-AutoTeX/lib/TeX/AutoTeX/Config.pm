package TeX::AutoTeX::Config;

#
# $Id: Config.pm,v 1.7.2.10 2011/02/02 06:26:25 thorstens Exp $
# $Revision: 1.7.2.10 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Config.pm,v $
#
# $Date: 2011/02/02 06:26:25 $
# $Author: thorstens $
#

use strict;
### use warnings;

our ($VERSION) = '$Revision: 1.7.2.10 $' =~ m{ \$Revision: \s+ (\S+) }x;

use parent qw(Exporter);
our @EXPORT_OK;
BEGIN {
  @EXPORT_OK = qw(
		  $DEFAULT_BRANCH
		  $DEFAULT_TEX_BIN_PATH
                  $AUTOTEX_TIMEOUT
                  $AUTOTEX_ENV_PATH
                  $TEX_PATH
                  $TEXCHR
                  $CRYPT
                  %TEX_BINARIES
                  $DVIPS
                  $TEX_ADMIN_ADDRESS
                  $MAIL_FAILURES_ADDRESS
                  $SENDMAIL
		  $DEFAULTPSRESOLUTION
                  $DIRECTIVE_FILE
                  $THIS_SITE
                 );
}

use vars @EXPORT_OK;

$DEFAULT_BRANCH = 'texlive/2009';
$DEFAULT_TEX_BIN_PATH = '/opt/texlive/2009/bin/arch:/bin';

$DIRECTIVE_FILE = '00README.XXX';

############################################################################
# The following variables are specific to individual arXiv sites (imported #
# from arXiv::Config::Site::*) They must be customized for other           #
# installations                                                            #
############################################################################
# use arXiv::Config::Site::AutoTeX;

# sendmail command for piping mail
#$SENDMAIL = $arXiv::Config::Site::AutoTeX::SENDMAIL;
$SENDMAIL = q{/usr/sbin/sendmail -t};

# decryption program for encrypted source files
#$CRYPT    = $arXiv::Config::Site::AutoTeX::CRYPT;
$CRYPT = q{};

# set the default resolution/mode for dvips using bitmap fonts
#$DEFAULTPSRESOLUTION = defined $arXiv::Config::Site::AutoTeX::DEFAULTPSRESOLUTION ?
#  $arXiv::Config::Site::AutoTeX::DEFAULTPSRESOLUTION :
#  600;
$DEFAULTPSRESOLUTION = 600;

# How long a latex process is allowed to run before being alarmed
#$AUTOTEX_TIMEOUT  = $arXiv::Config::Site::AutoTeX::AUTOTEX_TIMEOUT;
$AUTOTEX_TIMEOUT  = 300;

# The PATH for system tools needed by tex, etc. A chroot setup requires special consideration
#$AUTOTEX_ENV_PATH = $arXiv::Config::Site::AutoTeX::AUTOTEX_ENV_PATH;
$AUTOTEX_ENV_PATH = '/usr/local/bin:/usr/bin:/bin';

# In a chroot setup this specifies the new root directory.  It is assumed
# that the program is invoked from inside the new root, i.e. the working
# directory is a subdirectory thereof.
#$TEX_PATH         = $arXiv::Config::Site::AutoTeX::TEX_PATH;
$TEX_PATH = q{};

# The suid wrapper command used to switch to the chroot environment.
#$TEXCHR           = $arXiv::Config::Site::AutoTeX::TEXCHR;
$TEXCHR = q{/bin/sh -c};

# Name of the dvips binary (historical, dvihps, dvipsk, etc.)
#$DVIPS            = $arXiv::Config::Site::AutoTeX::DVIPS;
$DVIPS = 'dvips';

%TEX_BINARIES = (
		 HTEX      => 'tex',      # $arXiv::Config::Site::AutoTeX::HTEX,
		 TEX       => 'tex',      # $arXiv::Config::Site::AutoTeX::TEX,
		 BIGTEX    => 'bigtex',   # $arXiv::Config::Site::AutoTeX::BIGTEX,
		 HLATEX2E  => 'latex2e',  # $arXiv::Config::Site::AutoTeX::HLATEX2E,
		 HLATEX209 => 'hlatex',   # $arXiv::Config::Site::AutoTeX::HLATEX209,
		 LATEX2E   => 'latex2e',  # $arXiv::Config::Site::AutoTeX::LATEX2E,
		 LATEX209  => 'latex209', # $arXiv::Config::Site::AutoTeX::LATEX209,
		 BIGLATEX  => 'biglatex', # $arXiv::Config::Site::AutoTeX::BIGLATEX,
		 HLATEX    => 'latex',    # $arXiv::Config::Site::AutoTeX::HLATEX,
		 LATEX     => 'latex',    # $arXiv::Config::Site::AutoTeX::LATEX,
		 PDFLATEX  => 'pdflatex', # $arXiv::Config::Site::AutoTeX::PDFLATEX,
		 HPDFLATEX => 'pdflatex', # $arXiv::Config::Site::AutoTeX::PDFLATEX,
		 PDFTEX    => 'pdftex',   # $arXiv::Config::Site::AutoTeX::PDFTEX,
		);

#use arXiv::Config::Site::Email;

#$TEX_ADMIN_ADDRESS     = $arXiv::Config::Site::Email::TEX_ADMIN_ADDRESS;
$TEX_ADMIN_ADDRESS = q{};
#$MAIL_FAILURES_ADDRESS = $arXiv::Config::Site::Email::MAIL_FAILURES_ADDRESS;
$MAIL_FAILURES_ADDRESS = q{};

1;

__END__

=for stopwords AutoTeX arXiv arxiv.org perlartistic www-admin Schwander namespace

=head1 NAME

TeX::AutoTeX::Config - central configuration file for TeX::AutoTeX

=head1 DESCRIPTION

This is the main configuration file for TeX::AutoTeX. It contains all
configuration parameters for TeX::AutoTeX and allows TeX::AutoTeX to be used
separately from other arXiv software.

The settings in this file must be customized to reflect PATH settings and
executable names of the local TeX installation, maintainer email addresses,
etc.. The comments for each setting should be used as guidance.

In the sample configuration presented in this file those variables, which are
not identical across all arXiv sites, are imported from the
C<arXiv::Config::Site> namespace. These settings vary depending on the
capabilities of each mirror and their individual setup.

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
