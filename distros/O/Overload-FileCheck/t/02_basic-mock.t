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

use Overload::FileCheck qw{:all};

my @calls;

{
    note "no mocks at this point";

    ok -e q[/tmp],           "/tmp/exits";
    ok !-e q[/do/not/exist], "/do/not/exist";

    is \@calls, [], 'no calls';
}

{
    note "we are mocking -e => CHECK_IS_TRUE";
    mock_file_check(
        '-e' => sub {
            my $f = shift;

            note "mocked -e called....";

            push @calls, $f;
            return CHECK_IS_TRUE;
        }
    );

    ok -e q[/tmp],          "/tmp exits";
    ok -e q[/do/not/exist], "/do/not/exist now exist thanks to mock=1";
    is \@calls, [qw{/tmp /do/not/exist}], 'got two calls calls';
}

{
    note "mocking a second time with CHECK_IS_FALSE";

    like(
        dies {
            mock_file_check( '-e' => sub { CHECK_IS_FALSE } )
        },
        qr/\Q-e is already mocked by Overload::FileCheck/,
        "die when mocking a second time"
    );

    unmock_file_check('-e');

    unmock_file_check(qw{-e -f});

    note "we are mocking -e => CHECK_IS_FALSE";
    mock_file_check( '-e' => sub { CHECK_IS_FALSE } );

    ok !-e q[/tmp], "/tmp does not exist now...";
}

done_testing;
