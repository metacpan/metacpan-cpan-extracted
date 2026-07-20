#!/usr/bin/env perl
# get Sys::OsRelease::Lite version number from Sys::OsRelease changelog
#
# Copyright 2026 by Ian Kluft
# Open Source license Perl's Artistic License 2.0: <http://www.perlfoundation.org/artistic_license_2_0>
# SPDX-License-Identifier: Artistic-2.0

use v5.10;
use strict;
use warnings;
use utf8;
use feature qw(say);
use Carp    qw(carp croak);
use Readonly;
use CPAN::Changes;
use Versioning::Scheme::Semantic;

# constants
Readonly::Scalar my $Debug        => ( $ENV{SORL_DEBUG} // 0 ? 1 : 0 );
Readonly::Scalar my $ChangesFile  => 'Changes';
Readonly::Scalar my $VersionRE  => qr/\%VERSION\%/x;
Readonly::Scalar my $NextTokenRE  => qr/\{\{\$NEXT\}\}/x;
Readonly::Scalar my $NextTokenStr => '{{$NEXT}}';
Readonly::Hash my %GroupOrder => (
    MAJOR        => 0,
    "API CHANGE" => 1,
    MINOR        => 2,
    ENHANCEMENTS => 3,
    SECURITY     => 4,
    REVISION     => 5,
    "BUG FIXES"  => 6,
    DOCS         => 7,
);
Readonly::Hash my %GroupLevel => (
    MAJOR        => 0,
    "API CHANGE" => 0,
    MINOR        => 1,
    ENHANCEMENTS => 1,
    SECURITY     => 1,
    REVISION     => 2,
    "BUG FIXES"  => 2,
    DOCS         => 2,
);

# debugging statements when enabled
sub debug
{
    my @text = @_;
    if ($Debug) {
        say STDERR "debug: " . join( " ", @text );
    }
    return;
}

# load changelog data
sub get_changes
{
    return CPAN::Changes->load( $ChangesFile, next_token => $NextTokenRE, );
}

# find which level of semantic versioning to increment
sub get_semver_level
{
    my $changes      = shift;
    my $semver_level = 2;
    my @releases     = $changes->releases();
    my @groups       = $releases[-1]->groups();
    foreach my $group (@groups) {
        next if ( $group eq '' );
        debug "semver_level check($semver_level): $group/$GroupLevel{$group}";
        next if not exists $GroupLevel{$group};
        if ( $GroupLevel{$group} < $semver_level ) {
            $semver_level = $GroupLevel{$group};
            last if $semver_level == 0;
        }
    }
    debug "semver_level = $semver_level";
    return $semver_level;
}

# obtain current version and increment to return next version
sub find_version
{
    my $changes = get_changes();
    debug "received changes:", $changes->serialize(), "";

    # compute next version
    $changes->delete_empty_groups();
    my $semver_level = get_semver_level($changes);
    my @releases     = $changes->releases();
    my $rel_len      = scalar(@releases);
    if ( $releases[ $rel_len - 1 ]->version() ne $NextTokenStr ) {
        croak "Changes file entries must be added under $NextTokenStr to compute next version";
    }

    # if NEXT version in Changes has all empty sections, then use the current version
    my $found_nonempty = 0;
    my $next_release   = $releases[ $rel_len - 1 ];
    my $num_entries    = scalar @{ $next_release->{entries} // [] };
    for ( my $i = 0 ; $i < $num_entries ; $i++ ) {
        if ( ( scalar @{ $next_release->{entries}[$i]{entries} } ) > 0 ) {
            $found_nonempty = 1;
            last;
        }
    }

    # obtain current and compute next version
    my $prev_version = ( $rel_len >= 2 ) ? $releases[ $rel_len - 2 ]->version() : "0.0.0";
    debug "prev_version = $prev_version";
    my $prev_semver =
        Versioning::Scheme::Semantic->normalize_version($prev_version . "+lite");    # exception if invalid
    debug "prev_semver = $prev_semver";
    if ( not $found_nonempty ) {
        return $prev_semver;
    }
    my $next_semver =
        Versioning::Scheme::Semantic->bump_version( $prev_semver, { part => $semver_level } );
    debug "next_semver = $next_semver";
    return $next_semver;
}

#
# program main
#
{
    # source code filters to turn Sys::OsRelease into Sys::OsRelease::Lite
    say find_version();
}
