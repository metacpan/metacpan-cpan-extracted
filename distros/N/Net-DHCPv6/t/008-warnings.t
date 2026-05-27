#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::Option::SipServerD;

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
};

subtest '_warns counts carp warnings' => sub {
    my $cnt = _warns { require Carp; Carp::carp( 'test warning' ) };
    ok( $cnt, 'carp produced a warning' );
};

subtest '_warnings returns warning strings' => sub {
    my $w = _warnings { require Carp; Carp::carp( 'test warning' ) };
    ok( @$w, 'returned at least one warning' );
    like( $w->[0], qr/test warning/, 'warning matches expected string' );
};

done_testing;
