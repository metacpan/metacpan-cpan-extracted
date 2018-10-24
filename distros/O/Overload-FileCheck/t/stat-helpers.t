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

use Overload::FileCheck q{:stat};

use Fcntl (
    '_S_IFMT',     # bit mask for the file type bit field
                   #'S_IFPERMS',   # bit mask for file perms.
    'S_IFSOCK',    # socket
    'S_IFLNK',     # symbolic link
    'S_IFREG',     # regular file
    'S_IFBLK',     # block device
    'S_IFDIR',     # directory
    'S_IFCHR',     # character device
    'S_IFIFO',     # FIFO
);

is stat_as_directory(), [ 0, 0, S_IFDIR,  (0) x 10 ], 'stat_as_directory';
is stat_as_file(),      [ 0, 0, S_IFREG,  (0) x 10 ], 'stat_as_file';
is stat_as_symlink(),   [ 0, 0, S_IFLNK,  (0) x 10 ], 'stat_as_symlink';
is stat_as_socket(),    [ 0, 0, S_IFSOCK, (0) x 10 ], 'stat_as_socket';
is stat_as_chr(),       [ 0, 0, S_IFCHR,  (0) x 10 ], 'stat_as_chr';
is stat_as_block(),     [ 0, 0, S_IFBLK,  (0) x 10 ], 'stat_as_block';

if ( $> == 0 ) {
  is stat_as_file( uid => 'root', gid => 'root' ), [ 0, 0, S_IFREG, (0) x 10 ],
    'stat_as_file( uid => root, gid => root )';
}

{
    my $daemon_uid = getpwnam('daemon');
    my $wheel_gid  = getgrnam('wheel');

    if ( $daemon_uid && $wheel_gid ) {
        is stat_as_file( uid => 'daemon', gid => 'wheel' ),
          [ 0, 0, S_IFREG, 0, int $daemon_uid, int $wheel_gid, (0) x 7 ],
          'stat_as_file( uid => daemon, gid => wheel )';
    }

}

is stat_as_file( uid => 98765, gid => 1234 ),
  [ 0, 0, S_IFREG, 0, 98765, 1234, (0) x 7 ],
  'stat_as_file( uid => 98765, gid => 1234 )';

my @regular_file = ( 0, 0, S_IFREG, (0) x 10 );

my $now = time();
my $expect;

$expect = [@regular_file];
$expect->[7] = 1234;

is stat_as_file( size => 1234 ), $expect, 'size';

$expect = [@regular_file];
$expect->[8] = $now;
is stat_as_file( atime => $now ), $expect, 'atime';

$expect = [@regular_file];
$expect->[9] = $now;
is stat_as_file( mtime => $now ), $expect, 'mtime';

$expect = [@regular_file];
$expect->[10] = $now;
is stat_as_file( ctime => $now ), $expect, 'ctime';

$expect       = [@regular_file];
$expect->[8]  = 8;
$expect->[9]  = 9;
$expect->[10] = 10;
is stat_as_file( atime => 8, mtime => 9, ctime => 10 ), $expect, 'atime + mtime + ctime';

is stat_as_file( perms => 0755 ), [ 0, 0, S_IFREG | 0755, (0) x 10 ], 'stat_as_file with perms 0755';

done_testing;
