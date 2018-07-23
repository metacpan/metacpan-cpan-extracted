#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

# Copyright 2015 Roland van Ipenburg

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp qw(croak);
use Encode qw(encode);
use English q{-no_match_vars};
use File::Spec;
use File::Temp qw(tempfile);
use IO::File;
use File::Slurp qw(read_file);
use LWP::Simple qw(getstore);
use Perl::Tidy;

our $VERSION = 0.103;
use Readonly;

## no critic qw(prohibitCallsToUnexportedSubs)
Readonly::Scalar my $ZIP =>
  q{http://mirror.ctan.org/language/hyphenation-utf8.zip};
Readonly::Scalar my $PREFIX      => q{../};
Readonly::Scalar my $TARGET      => q{lib/TeX/Hyphen/Pattern/};
Readonly::Scalar my $TARGET_PATH => File::Spec->catdir( $PREFIX, $TARGET );
Readonly::Scalar my $MANIFEST    => File::Spec->catdir( $PREFIX, q{MANIFEST} );
Readonly::Scalar my $PM_EXT      => q{.pm};
Readonly::Scalar my $EMPTY       => q{};
Readonly::Scalar my $DASH        => q{-};
Readonly::Scalar my $UNDERSCORE  => q{_};
Readonly::Scalar my $NEWLINE     => qq{\n};

Readonly::Scalar my $FIND_LOCALE => qr{ .*/hyph-([^.]+)[.]lic[.]txt$ }smx;

Readonly::Array my @SECTIONS => qw(lic pat hyp);
## use critic

my $zip;
my ( $fh, $zip_name ) = tempfile();
my $rc;
if (
## no critic qw(prohibitCallsToUnexportedSubs)
    LWP::Simple::is_success(
## use critic
        $rc = LWP::Simple::getstore( $ZIP, $zip_name ),
    )
  )
{
    $zip = Archive::Zip->new();
    if ( $zip->read($zip_name) != AZ_OK ) {
        unlink $zip_name;
        ## no critic qw(RequireUseOfExceptions)
        croak 'read error';
        ## use critic
    }
}
else {
    ## no critic qw(RequireUseOfExceptions)
    croak "No success, $rc";
    ## use critic
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

sub get_data {
    my $locale = shift;
    my @sections;
    foreach my $section (@SECTIONS) {
        my $member =
          shift @{ [ $zip->membersMatching(qq{/hyph-$locale.$section.txt}) ] };
        push @sections,
          Encode::decode( q{utf8}, ( $member->contents || $EMPTY ) );
    }
    return @sections;
}

my $filename;
my $package;

# Prepare to rewrite the MANIFEST including the generated files:
my @files = File::Slurp::read_file( $MANIFEST, 'binmode' => ':utf8' );
## no critic qw(ProhibitCallsToUnexportedSubs RequireExplicitInclusion ProhibitCallsToUndeclaredSubs)
my $manifest = IO::File->new(qq{> $MANIFEST});
## use critic
foreach my $file (@files) {
    next if ( $file =~ m{$TARGET.*$PM_EXT}xsmg );
    ## no critic qw(RequireUseOfExceptions)
    print {$manifest} $file or croak "Can't write, stopped $ERRNO";
    ## use critic
}

while ( my $locale = shift @locales ) {
    $package = ucfirst $locale;
    $package =~ s/$DASH/$UNDERSCORE/xmgis;
    $filename = File::Spec->catdir( $TARGET_PATH, $package . $PM_EXT );
    my $target = IO::File->new( q{> } . $filename );
    $target->binmode(q{utf8});
    if ( defined $target ) {
        my $source = sprintf $template,
          ( $package, $::VERSION, $package, $package, get_data($locale) );
        my $destination;
        my $error = Perl::Tidy::perltidy(
            'source'      => \$source,
            'destination' => \$destination,
        );
        print {$target} $destination
          ## no critic qw(RequireUseOfExceptions)
          or croak "Can't write, stopped $ERRNO";
        ## use critic
        $target->close;
        $filename =~ s{^$PREFIX}{}smx;
        print {$manifest} $filename, $NEWLINE
          ## no critic qw(RequireUseOfExceptions)
          or croak qq{Can't write $filename, stopped $ERRNO};
        ## use critic
    }
    else {
        ## no critic qw(RequireUseOfExceptions)
        croak qq{Can't open $filename, stopped $ERRNO};
        ## use critic
    }
}

unlink $zip_name;

## no critic qw(RequirePodAtEnd)

=encoding utf8

=for stopwords CTAN Ipenburg

=head1 NAME

build_catalog_from_ctan.pl - Script to generate the different pattern module
files based on the sources provided by CTAN.

=head1 USAGE

./build_catalog_from_ctan.pl

=head1 DESCRIPTION

This script gets the pattern files as used by TeX related applications from
CTAN and turns them into Perl modules that can be used in
L<TeX::Hyphen::Pattern|TeX::Hyphen::Pattern>.

=head1 REQUIRED ARGUMENTS

There are no required arguments.

=head1 OPTIONS

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roland van Ipenburg  C<< <ipenburg@xs4all.nl> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 by Roland van Ipenburg

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

=head1 Copyright

=begin text
%s
=end text

=cut

__DATA__
\patterns{
%s
}
\hyphenation{
%s
}
