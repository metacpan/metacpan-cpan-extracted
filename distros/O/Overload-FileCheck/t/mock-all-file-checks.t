#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};

my @exist     = qw{cherry banana apple};
my @not_there = qw{mum and dad};

ok mock_all_file_checks( \&my_custom_check ), 'mock_all_file_checks succeeds';

my $last_check_called;

sub my_custom_check {
    my ( $check, $f ) = @_;

    note "mocked check -$check called for ", $f;
    $last_check_called = $check;

    return CHECK_IS_TRUE  if grep { $_ eq $f } @exist;
    return CHECK_IS_FALSE if grep { $_ eq $f } @not_there;

    # we have no idea about these files
    return FALLBACK_TO_REAL_OP;
}

my $ALL_CHECKS = Overload::FileCheck::_get_filecheck_ops_map();

foreach my $c ( sort keys %$ALL_CHECKS ) {
    next if $c =~ qr{^l?stat$};    # do not bother with these they are not file checks

    my $do_check = sub {
        my ($input) = @_;
        return eval qq[ -$c \$input];
    };

    foreach my $f (@exist) {
        ok( $do_check->($f), "-$c '$f' is true" );
    }

    is $last_check_called, $c, "last check called was -$c";

    foreach my $f (@not_there) {
        ok( !$do_check->($f), "-$c '$f' is false" );
    }

    is $last_check_called, $c, "last check called was -$c";
}

$last_check_called = '';

ok stat($0);
ok lstat($0);

is $last_check_called, '', "stat or lstat are not mocked";

ok unmock_all_file_checks(), "unmock_all_file_checks";

undef $last_check_called;
my $check = -e $^X;
ok $check, "check succeeds";
is $last_check_called, undef, 'custom function not called after unmock_all_file_checks';

done_testing;
