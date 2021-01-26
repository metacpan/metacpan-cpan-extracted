#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2009-2021, Roland van Ipenburg
use strict;
use warnings;

use utf8;
use 5.014000;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Encode qw(encode);
use English q{-no_match_vars};
use File::Basename;
use File::Spec;
use File::Temp qw(tempfile);
use Getopt::Long;
use IO::File;
use File::Slurp qw(read_file);
use Log::Log4perl qw(:easy get_logger);
use HTTP::Tiny::Cache;
use Pod::Usage;
use Perl::Tidy;
use Progress::Any;
use Progress::Any::Output q{TermProgressBarColor};

our $VERSION = v1.1.8;
use Readonly;

## no critic qw(prohibitCallsToUnexportedSubs)
Readonly::Scalar my $ZIP =>
  q{http://mirror.ctan.org/language/hyphenation-utf8.zip};
Readonly::Scalar my $PREFIX      => q{../};
Readonly::Scalar my $TARGET      => q{lib/TeX/Hyphen/Pattern/};
Readonly::Scalar my $TARGET_PATH => File::Spec->catdir( $PREFIX, $TARGET );
Readonly::Scalar my $PM_EXT      => q{.pm};
Readonly::Scalar my $EMPTY       => q{};
Readonly::Scalar my $SPACE       => q{ };
Readonly::Scalar my $DASH        => q{-};
Readonly::Scalar my $UNDERSCORE  => q{_};
Readonly::Scalar my $NEWLINE     => qq{\n};
Readonly::Scalar my $CACHE       => 3600;
Readonly::Scalar my $KEY         => q{HTTP_TINY_CACHE_MAX_AGE};
Readonly::Scalar my $LOG_CONF    => q{build_catalog_log.conf};
Readonly::Array my @DEBUG_LEVELS => ( $WARN, $INFO, $DEBUG, $TRACE );

Readonly::Scalar my $FIND_LOCALE => qr{ .*/hyph-([^./]+)[.]tex$ }smx;

Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Array my @GETOPTIONS  => ( q{verbose|v+}, q{max_age|m=i} );
Readonly::Hash my %OPTS_DEFAULT => ( 'max_age' => $CACHE );
Readonly::Hash my %LOG          => (
    'DOWNLOAD_STARTED'  => q{Started download of resource '%s'},
    'DOWNLOAD_FINISHED' => q{Finished download of resource '%s'},
    'DOWNLOAD_WRITE'    => q{Writing download temporarily to file '%s'},
    'ERROR_WRITE'       => q{Error writing to file '%s', stopped %s},
    'ERROR_OPEN'        => q{Error opening file '%s', stopped %s},
    'ERROR_CLOSE'       => q{Error closing file '%s', stopped %s},
    'ERROR_DOWNLOAD'    => q{Error downloading resource '%s'},
    'ERROR_ZIP'         => q{Error reading file '%s' as ZIP archive},
    'PACKAGE'           => q{Adding package '%s' to catalog},
    'FILE'              => q{Extracting data from file '%s' for locale '%s'},
    'CONTENTS'          => qq{Contents of file '%s':\n%s},
);
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

my $zip;
my ( $fh, $zip_name ) = File::Temp::tempfile();
$log->info( sprintf $LOG{'DOWNLOAD_STARTED'}, $ZIP );
## no critic (RequireLocalizedPunctuationVars)
$ENV{$KEY} = ( $opts{'max_age'} ) // $ENV{$KEY} // $CACHE;
## use critic
my $response = HTTP::Tiny::Cache->new->get($ZIP);
if ( ${$response}{'success'} ) {
    $log->info( sprintf $LOG{'DOWNLOAD_FINISHED'}, $ZIP );
    $log->debug( sprintf $LOG{'DOWNLOAD_WRITE'}, $zip_name );
    print {$fh} ${$response}{'content'}
      or $log->logdie( sprintf $LOG{'ERROR_WRITE'}, $zip_name, $ERRNO );
    close $fh or $log->error( sprintf $LOG{'ERROR_CLOSE'}, $zip_name, $ERRNO );
    $zip = Archive::Zip->new();
## no critic qw(prohibitCallsToUnexportedSubs)
    if ( $zip->read($zip_name) != Archive::Zip::AZ_OK ) {
## use critic
        unlink $zip_name;
        $log->logdie( sprintf $LOG{'ERROR_ZIP'}, $zip_name );
    }
}
else {
    $log->logdie( sprintf $LOG{'ERROR_DOWNLOAD'}, $ZIP );
}

## no critic qw(prohibitCallsToUnexportedSubs)
my $template = File::Slurp::read_file( \*DATA, 'binmode' => ':utf8' );
## use critic

sub get_locale {
    my $filename = shift;
    if ( $filename =~ s{$FIND_LOCALE}{$1}smx ) {
        return $filename;
    }
    return ();
}

my @locales =
  sort map { get_locale( $_->fileName ) } $zip->membersMatching($FIND_LOCALE);
$log->info( +@locales . q{ locales found in the zip: } . join $SPACE,
    @locales );

sub get_data {
    my $locale = shift;
    my $file   = qq{/hyph-$locale.tex};
    $log->debug( sprintf $LOG{'FILE'}, $file, $locale );
    my $member =
      shift @{ [ $zip->membersMatching($file) ] };
    $log->trace( sprintf $LOG{'CONTENTS'}, $file, $member->contents || $EMPTY );
    my $re_starts = qr{(%|\\(?:message|bgroup|lccode|begingroup|def|edef))}smx;
    my $re_lic    = qr{(?<lic>(?:(?:$re_starts\N*.)|\v)+)}smx;
    my $re_pat    = qr{(?<pat>\\(patterns[{].*[}]|input[ ]\S+))?}smx;
    my $re_hyp    = qr{\s*(?<hyp>\\hyphenation[{].*[}])?}smx;
    Encode::decode( q{utf8}, ( $member->contents || $EMPTY ) ) =~
      m{$re_lic$re_pat$re_hyp}gsmx;
    Encode::decode( q{utf8}, ( $member->contents || $EMPTY ) ) =~
      m{$re_lic$re_pat$re_hyp}gsmx;
    my $lic = $LAST_PAREN_MATCH{'lic'} || $EMPTY;
    my $pat = $LAST_PAREN_MATCH{'pat'} || $EMPTY;
    my $hyp = $LAST_PAREN_MATCH{'hyp'} || $EMPTY;
    $lic =~ s{^%[ ]?}{}gsmx;
## no critic qw(RequireLineBoundaryMatching)
    $lic =~ s{\s+$}{}gsx;
## use critic
    return ( $lic, $pat, $hyp );
}

sub generate {
    my $filename;
    my $package;

    my $progress;
    ( $log->is_info() && !$log->is_debug() )
      && (
        $progress = Progress::Any->get_indicator(
            'task'   => q{generate},
            'pos'    => 0,
            'target' => ~~ @locales,
        )
      );

    while ( my $locale = shift @locales ) {
        $package = ucfirst $locale;
        $package =~ s/$DASH/$UNDERSCORE/xmgis;
        $filename = File::Spec->catdir( $TARGET_PATH, $package . $PM_EXT );
        my $target = IO::File->new( q{> } . $filename );
        $progress
          && $progress->update(
            'message' => sprintf $LOG{'PACKAGE'},
            $package,
          );
        $target->binmode(q{utf8});
        if ( defined $target ) {
            my $source = sprintf $template,
              (
                $package, $::VERSION, $package, $package, $package,
                $package, get_data($locale),
              );
            my $destination;
            my $error = Perl::Tidy::perltidy(
                'source'      => \$source,
                'destination' => \$destination,
            );
            print {$target} $destination
              or $log->logdie( sprintf $LOG{'ERROR_WRITE'}, $target, $ERRNO );
            $target->close
              or $log->error( sprintf $LOG{'ERROR_CLOSE'}, $filename, $ERRNO );
        }
        else {
            $log->logdie( sprintf $LOG{'ERROR_OPEN'}, $filename, $ERRNO );
        }
    }
    $progress && $progress->finish();
    return;
}

generate();

unlink $zip_name;

## no critic qw(RequirePodAtEnd)

=encoding utf8

=for stopwords CTAN Ipenburg MERCHANTABILITY Readonly

=head1 NAME

build_catalog_from_ctan.pl - generate the pattern module files from the CTAN
upstream source

=head1 USAGE

./build_catalog_from_ctan.pl

=head1 DESCRIPTION

For package maintainers and to adhere to the open source licenses of the
patterns, this script can be used to generate the pattern files from their
upstream source on L<CTAN|https:://www.ctan.org>.

=head1 REQUIRED ARGUMENTS

There are no required arguments.

=head1 OPTIONS

=over 4

=item * B<max_age>: The maximum time in seconds the remote file stays cached.
Default one hour.

=item * B<verbose>: Be more verbose.

=back

=head1 DIAGNOSTICS

The script uses L<Log::Log4perl> for logging and that can be configured in a
file named C<build_catalog_log.conf>.

=head1 EXIT STATUS

=head1 CONFIGURATION

The environment variable I<HTTP_TINY_CACHE_MAX_AGE> is used to set the default
caching period for requests to 3600 seconds if it wasn't set already, or to
the value given by the I<max_age> option.

=head1 DEPENDENCIES

=over 4

=item * L<Archive::Zip|Archive::Zip>
=item * L<Encode|Encode>
=item * L<English|English>
=item * L<File::Basename|File::Basename>
=item * L<File::Spec|File::Spec>
=item * L<File::Temp|File::Temp>
=item * L<Getopt::Long|Getopt::Long>
=item * L<IO::File|IO::File>
=item * L<File::Slurp|File::Slurp>
=item * L<Log::Log4perl|Log::Log4perl>
=item * L<HTTP::Tiny::Cache|HTTP::Tiny::Cache>
=item * L<Pod::Usage|Pod::Usage>
=item * L<Perl::Tidy|Perl::Tidy>
=item * L<Readonly|Readonly>
=item * L<Progress::Any|Readonly>
=item * L<Progress::Any::Output::TermProgressBarColor|Progress::Any::Output::TermProgressBarColor>

=back

=head1 INCOMPATIBILITIES

This script only aims to get basic TeX stuff needed for hyphenation, it
doesn't properly parse TeX syntax, so complicated TeX pattern are likely to
fail, but also not very likely to occur.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<Bitbucket|
https://bitbucket.org/rolandvanipenburg/tex-hyphen-pattern/issues>.

=head1 AUTHOR

Roland van Ipenburg  C<< <roland@rolandvanipenburg.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2021 by Roland van Ipenburg

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

package TeX::Hyphen::Pattern::%s v%vd;
use strict;
use warnings;
use 5.014000;
use utf8;

use Moose;

my $pattern_file = q{};
while (<DATA>) {
	 $pattern_file .= $_;
}

sub pattern_data {
	return $pattern_file;
}

sub version {
	return $TeX::Hyphen::Pattern::%s::VERSION;
}

1;
## no critic qw(RequirePodAtEnd RequireASCII ProhibitFlagComments)
=encoding utf8

=for stopwords CTAN Ipenburg %s

=head1 NAME

TeX::Hyphen::Pattern::%s - class for hyphenation in locale %s

=head1 SUBROUTINES/METHODS

=over 4

=item $pattern-E<gt>pattern_data();

Returns the pattern data.

=item $pattern-E<gt>version();

Returns the version of the pattern package.

=back

=head1 COPYRIGHT

=begin text

%s

=end text

=cut

__DATA__
%s
%s
