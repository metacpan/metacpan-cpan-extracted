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
use Errno ();

{
    note "no mocks at this point";

    ok -e q[/tmp],           "/tmp/exits";
    ok !-e q[/do/not/exist], "/do/not/exist";

    my ( $check, $errno_int );

    $check = -e q[/do/not/exist];

    # do not check the errno string, as it depends on the locale
    $errno_int = int($!);

    ok !$check, "file does not exist";

    is $errno_int, Errno::ENOENT(), "ERRNO int value set";

    $check     = -e $^X;
    $errno_int = int($!);

    ok $check, q[$^X exists];
    is $errno_int, Errno::ENOENT(), "ERRNO was not reset";
}

{
    local $! = 0;

    my $existing_file = q[/there];
    my $missing_file  = q[/not-there];

    mock_file_check(
        '-e' => sub {
            my $f = shift;
            return CHECK_IS_FALSE if $f eq $missing_file;
            return CHECK_IS_TRUE  if $f eq $existing_file;

            # we do not know and let perl check it for us
            return FALLBACK_TO_REAL_OP;

        }
    );

    my ( $check, $errno_int );

    is int($!), 0, 'errno=0 at startup';

    note "check existing file";
    $check     = -e $existing_file;
    $errno_int = int($!);

    ok $check, 'existing_file is there';
    is $errno_int, 0, '$! is not set';

    note "check missing file";
    $check     = -e $missing_file;
    $errno_int = int($!);

    ok !$check, 'missing_file not there';
    is $errno_int, Errno::ENOENT(), '$! is set to the default value';

    note "check existing file again";
    $check     = -e $existing_file;
    $errno_int = int($!);

    ok $check, 'existing_file is there';
    is $errno_int, Errno::ENOENT(), '$! was not reset';

    ok -e $^X, q[$^X exists];
    is int($!), Errno::ENOENT(), '$! was not reset when fallback to original OP';

    unmock_all_file_checks();
}

{
    note "User provide its own ERRNO error";
    local $! = 0;

    note "we are mocking -e => 1";
    mock_file_check(
        '-e' => sub {
            my $f = shift;
            note "mocked -e called....";

            $! = Errno::EINTR();    # set errno

            return CHECK_IS_FALSE;
        }
    );

    my $check = -e q[/tmp];

    # do not check the errno string, as it depends on the locale
    my $errno_int = int($!);

    ok !$check, "/tmp does not exist";
    is $errno_int, Errno::EINTR(), "ERRNO int value set to Errno::EINTR()";

    unmock_all_file_checks();
}

done_testing;
