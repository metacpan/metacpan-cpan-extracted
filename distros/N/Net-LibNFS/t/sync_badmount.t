#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal;
use Test::Deep;

use Net::LibNFS ();

use Errno;

my $nfs = Net::LibNFS->new();

my $err = exception {
    $nfs->mount('localhost', '/home' . rand);
};

cmp_deeply(
    $err,
    all(
        Isa('Net::LibNFS::X::NFSError'),
        methods(
            [ get => 'errno' ] => any(
                Errno::EPERM,
                Errno::EIO,
                Errno::EFAULT,
            ),
        ),
    ),
    'expected error',
) or diag explain $err;

done_testing;
