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

my $call = 0;
my $last_call_for;
{
    ok mock_all_from_stat( \&my_stat ), "mock_all_from_stat";
    ok -f "/a/b/c/" && -f _, "this is a file";
    stat_is_called_once();

    $call = 0;
    ok -f "/a/b/c/" && !-d _, "not a directory";
    stat_is_called_once();

    ok unmock_all_file_checks(), 'unmock_all_file_checks';
}

{
    $call = 0;
    ok mock_all_file_checks( \&my_custom_check ), 'mock_all_file_checks';
    ok -f "/a/b/c/" && -f _, "this is a file";
    is $call, 2, "my_custom_check is called twice";
    is $last_call_for, "/a/b/c/";

    $call = 0;
    ok -f "/a/b/c/" && !-d _, "not a directory";
    is $call, 2, "my_custom_check is called twice";
    is $last_call_for, "/a/b/c/";

    ok unmock_all_file_checks(), 'unmock_all_file_checks';
}

done_testing;

sub stat_is_called_once {
    if ( $] >= 5.016 ) {
        is $call, 1, "my_stat only called once";
    }
    else {
        todo "need to adjust _ check for Perl <= 5.014" => sub {
            is $call, 1, "my_stat only called once";
        };
    }

    return;
}

sub my_stat {
    ++$call;
    return stat_as_file();
}

sub my_custom_check {
    my ( $check, $f ) = @_;

    ++$call;
    $last_call_for = $f;

    return CHECK_IS_TRUE if $check ne 'd';
    return CHECK_IS_FALSE;
}
