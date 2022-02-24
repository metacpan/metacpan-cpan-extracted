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

use Overload::FileCheck qw(CHECK_IS_FALSE CHECK_IS_TRUE FALLBACK_TO_REAL_OP);

use File::Temp qw{ tempfile tempdir };

my %STATS;

# non existing but mocked
my $FILENAME;
my $FAKE_DIR;

{
    my ( $fh, $filename ) = tempfile();
    $STATS{'file'} = [ stat($filename) ];
    unlink $filename;

    $FILENAME = "$filename";

    my $dir = tempdir( CLEANUP => 1 );

    $STATS{'dir'} = [ stat("$dir") ];

    $STATS{'perl'} = [ stat($^X) ];

    $FAKE_DIR = "$dir/not/there";
}

my $current_test = "$0";

our $call_my_stat;

ok !-e $FILENAME, "filename does not exist";
ok !-d $FAKE_DIR, "directory does not exis";

ok !$call_my_stat, 'start - without mock';

# note: we are just mocking stat here...
ok Overload::FileCheck::mock_all_from_stat( \&my_stat ), "mock_all_from_stat succees";

is [ stat( $FILENAME ) ], $STATS{'file'}, "stats for file";
ok $call_my_stat, "stat is now mocked";
ok -e $FILENAME, "-e filename";
ok -f $FILENAME, "-f filename";

ok -e $FILENAME && -f _, "-e filename && -f _";

is -l $FILENAME || -e $FILENAME, 1, q[-l $f || -e $f];
is -l $FILENAME || -e _, 1, q[-l $f || -e _];

is [ stat('/empty') ], [], "stat /empty";

is -l q[/empty] || -e q[/empty], undef, q[-l /empty || -e /empty];
is -l q[/empty] || -e _, undef, q[-l /empty || -e _];

# --- END ---
ok Overload::FileCheck::unmock_all_file_checks(), "unmock all";
done_testing;

exit;

sub my_stat {
    my ( $opname, $file_or_handle ) = @_;

    note "=== my_stat is called. Type: ", $opname, " File: ", $file_or_handle;
    ++$call_my_stat;

    my $f = $file_or_handle;               # alias to use a shorter name later...

    return $STATS{'file'} if $f eq $FILENAME;
    return $STATS{'dir'} if $f eq $FAKE_DIR;

    return [] if $f eq '/empty';

    return FALLBACK_TO_REAL_OP();
}

sub stat_for_a_directory {
    return $STATS{'dir'};
}

sub stat_for_a_binary {
    return $STATS{'perl'};
}

sub stat_for_a_tty {
    return $STATS{'tty'};
}

1;