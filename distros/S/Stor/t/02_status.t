#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use Mock::Quick;
use Test::Exception;

my $QX_CALLBACK = sub {};
use Test::Mock::Cmd 'qx' => sub { diag(explain(\@_)); $QX_CALLBACK->() };

use Stor;

my $storage_pairs = [
    [ Path::Tiny->tempdir(), Path::Tiny->tempdir(), ],
    [ Path::Tiny->tempdir(), Path::Tiny->tempdir(), ],
];

my $stor = Stor->new(
    storage_pairs => $storage_pairs,
    statsite => qobj( increment => 1 ),
);

my $c = qobj( render => 1);


$QX_CALLBACK = sub { return "/\n" };

throws_ok { $stor->status($c) } qr/Storage .* is not mounted/;


$QX_CALLBACK = sub { return "/a_mountpoint\n" };

lives_ok { $stor->status($c) } 'it worked';
