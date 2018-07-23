#!/usr/bin/env perl -w    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

use utf8;
use 5.014000;

BEGIN { our $VERSION = '0.103'; }

use Carp qw(croak);
use Cwd qw(abs_path);
use Encode;
use English qw(-no_match_vars);
use File::Basename;
use File::Find;
use File::Slurp qw(read_file);
use File::Temp;
use Getopt::Long;
use IO::File;
use Log::Log4perl qw(:easy get_logger);
use Perl::Tidy;
use TeX::Hyphen;
use SVN::Client;
use URI;
use URI::URL;
use WWW::Mechanize;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY      => q{};
Readonly::Scalar my $NEWLINE    => qq{\n};
Readonly::Scalar my $DASH       => q{-};
Readonly::Scalar my $UNDERSCORE => q{_};
Readonly::Scalar my $SLASH      => q{/};
Readonly::Scalar my $HYPH_NAME =>
  q{(?:(?:hyph[-_]|^)([^.?]+)\.(?:tex|dic|pat))};

Readonly::Scalar my $CASE_CONFLICT => q{^$};

Readonly::Scalar my $INCOMPATIBLE => q{^(Quote_.*)$};
Readonly::Scalar my $PM_EXT       => q{.pm};
Readonly::Scalar my $AUTOCHECK    => 1;
Readonly::Scalar my $PREFIX       => q{/../};
Readonly::Scalar my $TARGET       => q{lib/TeX/Hyphen/Pattern/};
Readonly::Scalar my $TARGET_PATH  => $PREFIX . $TARGET;
Readonly::Scalar my $MANIFEST     => $PREFIX . q{MANIFEST};
Readonly::Scalar my $ISO          => q{ISO};
Readonly::Scalar my $ENCODINGS    => q{^(KOI8-R|ISO8859-(\d+))};
Readonly::Scalar my $LOG_CONF     => q{build_catalog_log.conf};
Readonly::Array my @DEBUG_LEVELS  => ( $FATAL, $INFO, $WARN, $DEBUG );

Readonly::Hash my %REPO => (
    'utf' => {
        'root'   => q{svn://tug.org/texhyphen/trunk/hyph-utf8},
        'filter' => qr{\bhyph-.*.tex$ }xsmi,
    },
);
Readonly::Hash my %LOG => ( 'EXPORT' => q{Exporting from '%s' to '%s'}, );
Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Array my @GETOPTIONS  => (q{verbose|v+});
Readonly::Hash my %OPTS_DEFAULT => ();
## use critic

Getopt::Long::Configure(@GETOPT_CONFIG);
my %opts = %OPTS_DEFAULT;
Getopt::Long::GetOptions( \%opts, @GETOPTIONS ) or Pod::Usage::pod2usage(2);

if ( -r $LOG_CONF ) {
## no critic qw(ProhibitCallsToUnexportedSubs)
    Log::Log4perl::init_and_watch($LOG_CONF);
## use critic
}
else {
## no critic qw(ProhibitCallsToUnexportedSubs)
    Log::Log4perl::easy_init($ERROR);
## use critic
}
my $log = Log::Log4perl->get_logger( File::Basename::basename $PROGRAM_NAME );
$log->level(
    $DEBUG_LEVELS[
      (
          ( $opts{'verbose'} || 0 ) > $#DEBUG_LEVELS
          ? $#DEBUG_LEVELS
          : $opts{'verbose'}
      )
      || 0
    ],
);

my $template = $EMPTY;
while (<DATA>) {
    $template .= $_;
}

my $ctx = SVN::Client->new();
my $rel = dirname( abs_path __FILE__ ) . $SLASH;

my $dir = File::Temp->newdir();
$log->debug( sprintf $LOG{'EXPORT'}, $REPO{'utf'}{'root'}, $dir->dirname );
$ctx->export( $REPO{'utf'}{'root'}, $dir->dirname, 'HEAD', 1 );

# Prepare to rewrite the MANIFEST including the generated files:
my @files = read_file qq{$rel$MANIFEST};
## no critic qw(ProhibitCallsToUnexportedSubs RequireExplicitInclusion ProhibitCallsToUndeclaredSubs)
my $manifest = IO::File->new("> $rel$MANIFEST");
## use critic
foreach my $file (@files) {
    next if ( $file =~ m{$TARGET.*$PM_EXT}xsmg );
    ## no critic qw(RequireUseOfExceptions)
    print {$manifest} $file or croak "Can't write, stopped $ERRNO";
    ## use critic
}

find( \&patterns, ( $dir->dirname ) );

sub patterns {
    ## no critic qw(ProhibitUnusedCapture)
    if (/^hyph-(?<locale>.*)[.]tex$/gsmx) {
        ## use critic
        my $locale = $LAST_PAREN_MATCH{'locale'};
        $log->debug(qq{Found file '$_' as pattern for locale '$locale'});
        my $hyp     = TeX::Hyphen->new($File::Find::name);
        my $package = $locale;
        $package =~ s/$DASH/$UNDERSCORE/xmgis;
        $package =~ s/[.]/$UNDERSCORE/xmgis;
        $package = ucfirst $package;
        return if ( $package =~ /$CASE_CONFLICT/xmgs );
        my $filename = $package . $PM_EXT;
        my $content = read_file( $File::Find::name, 'binmode' => ':utf8' );

        if ( my ($encoding) = $content =~ /$ENCODINGS/xmis ) {
            $encoding =~ s/($ISO)(\d)/$1$DASH$2/xmgis;
            $content = Encode::decode( $encoding, $content );
        }
        ## no critic qw(ProhibitCallsToUnexportedSubs RequireExplicitInclusion ProhibitCallsToUndeclaredSubs)
        my $fh = IO::File->new("> $rel$TARGET_PATH$filename");
        ## use critic
        if ( defined $fh ) {
            $fh->binmode(':utf8');
            my $svn_path = $File::Find::name;
            my $svn_root = $dir->dirname;
            $svn_path =~ s{$svn_root}{}gsmx;
            my $src    = $REPO{'utf'}{'root'} . $svn_path;
            my $ver    = ( $package =~ /$INCOMPATIBLE/xmgs ) ? 0 : $::VERSION;
            my $source = sprintf $template,
              ( $package, $ver, $package, $package, $src, $content );
            my $destination;
            my $error = Perl::Tidy::perltidy(
                'source'      => \$source,
                'destination' => \$destination,
            );
            print {$fh} $destination
              ## no critic qw(RequireUseOfExceptions)
              or croak "Can't write, stopped $ERRNO";
            ## use critic
            $fh->close;
            print {$manifest} $TARGET, $filename, $NEWLINE
              ## no critic qw(RequireUseOfExceptions)
              or croak "Can't write, stopped $ERRNO";
            ## use critic
        }
        else {
            ## no critic qw(RequireUseOfExceptions)
            croak "Can't open $TARGET_PATH$filename, $ERRNO";
            ## use critic
        }
    }
    return;
}
$manifest->close;

## no critic qw(RequirePodAtEnd)
#

=encoding utf8

=for stopwords CTAN OpenOffice Ipenburg lth

=head1 NAME

build_catalog.pl - Script to generate the different pattern module
files based on the sources provided by CTAN and OpenOffice.

=head1 USAGE

./build_catalog.pl

=head1 DESCRIPTION

This script connects to L<http://tug.org/svn/> to get the sources of the TeX
hyphenation files and L<http://svn.services.openoffice.org/ooo/> to get the
sources of the OpenOffice hyphenation files. It turns them into usable Perl
packages and updates the MANIFEST to include the generated module files.

=head1 REQUIRED ARGUMENTS

There are no required arguments.

=head1 OPTIONS

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

The DATA section in this file is used as a template to generate the modules.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

Both sources have patterns for "en_US" and "en_GB" and because those modules
conflict on HFS+ when they only differ in case the OpenOffice source
patterns for these locales are ignored.

=head1 BUGS AND LIMITATIONS

Why does Th_lth fail? We don't do lth encoding?

=head1 AUTHOR

Roland van Ipenburg  C<< <ipenburg@xs4all.nl> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2018 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__DATA__
## no critic qw(RequirePodSections)    # -*- cperl -*-
# This file is auto-generated by the Perl TeX::Hyphen::Pattern Suite hyphen
# pattern catalog generator. This code generator comes with the
# TeX::Hyphen::Pattern module distribution in the tools/ directory
#
# Do not edit this file directly.

package TeX::Hyphen::Pattern::%s %s;
use strict;
use warnings;
use 5.014000;
use utf8;

use Moose;

my $pattern_file = q{};
while (<DATA>) {
	 $pattern_file .= $_;
}

sub data {
	return $pattern_file;
}

sub version {
	return $TeX::Hyphen::Pattern::%s::VERSION;
}

1;
## no critic qw(RequirePodAtEnd RequireASCII ProhibitFlagComments)
=encoding utf8

=head1 C<%s> hyphenation pattern class

=head1 SUBROUTINES/METHODS

=over 4

=item $pattern-E<gt>data();

Returns the pattern data.

=item $pattern-E<gt>version();

Returns the version of the pattern package.

=back

=head1 Copyright

The copyright of the patterns is not covered by the copyright of this package
since this pattern is generated from the source at
L<%s>

The copyright of the source can be found in the DATA section in the source of
this package file.

=cut

__DATA__
%s
