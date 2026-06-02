#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP, qw(is ok like subtest done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::Option::SipServerD;
use Net::DHCPv6::Option::ORO;
use Net::DHCPv6::Option::Preference;
use Net::DHCPv6::Option::ElapsedTime;
use Net::DHCPv6::Option::StatusCode;
use Net::DHCPv6::Option::RapidCommit;
use Net::DHCPv6::Option::DomainList;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::Option::SntpServers;
use Net::DHCPv6::DUID;

# Warning-testing pattern for use with strictures 2.
#
# strictures 2 makes most warning categories fatal, which breaks
# Test2::Tools::Warnings' local $SIG{__WARN__} approach (the block
# die()s after the handler returns).  Instead we use eval + a local
# $SIG{__WARN__} which works for all warnings, fatal or not.
#
# Carp::carp-based deprecation warnings work with both approaches
# because carp calls CORE::warn() without triggering a fatal category.

sub _warns (&) {
    my $code  = shift;
    my $count = 0;
    local $SIG{__WARN__} = sub { $count++ };
    eval { $code->() };
    return $count;
}

sub _warnings (&) {
    my $code = shift;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $code->() };
    return \@warnings;
}

sub _no_warnings (&) {
    my $code  = shift;
    my $count = 0;
    local $SIG{__WARN__} = sub { $count++ };
    eval { $code->() };
    return $count == 0;
}

# ---- Tests ----

subtest 'clean code produces no warnings' => sub {
    ok(
        _no_warnings {
            my $sd = Net::DHCPv6::Option::SipServerD->new;
            is( $sd->domains, [], 'SipServerD defaults to empty list' );
        },
        'no warnings during SipServerD default construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::ORO->new( requested_options => [ 23, 24 ] );
            is( $o->code, 6, 'ORO construction clean' );
        },
        'no warnings during ORO construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::Preference->new( value => 255 );
            is( $o->code, 7, 'Preference construction clean' );
        },
        'no warnings during Preference construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::ElapsedTime->new( centiseconds => 1000 );
            is( $o->code, 8, 'ElapsedTime construction clean' );
        },
        'no warnings during ElapsedTime construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::StatusCode->new( status_code => 0, message => 'OK' );
            is( $o->code, 13, 'StatusCode construction clean' );
        },
        'no warnings during StatusCode construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::RapidCommit->new;
            is( $o->code, 14, 'RapidCommit construction clean' );
        },
        'no warnings during RapidCommit construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::DomainList->new( domains => [] );
            is( $o->code, 24, 'DomainList construction clean' );
        },
        'no warnings during DomainList construction'
    );

    ok(
        _no_warnings {
            my $duid = Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 123_456, pack( 'H*', '001122334455' ) );
            my $o    = Net::DHCPv6::Option::ClientId->new( duid => $duid );
            is( $o->code, 1, 'ClientId construction clean' );
        },
        'no warnings during ClientId construction'
    );

    ok(
        _no_warnings {
            my $o = Net::DHCPv6::Option::SntpServers->new( servers => ['2001:db8::1'] );
            is( $o->code, 31, 'SntpServers construction clean' );
        },
        'no warnings during SntpServers construction'
    );
};

subtest '_warns counts carp warnings' => sub {
    my $cnt = _warns { require Carp; Carp::carp( 'test warning' ) };
    ok( $cnt, 'carp produced a warning' );
};

subtest '_warnings returns warning strings' => sub {
    my $w = _warnings { require Carp; Carp::carp( 'test warning' ) };
    ok( @{$w}, 'returned at least one warning' );
    like( $w->[0], qr/test warning/, 'warning matches expected string' );
};

done_testing;
