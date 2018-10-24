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

use Overload::FileCheck ();

is Overload::FileCheck::_loaded(), 1, '_loaded';

is int Overload::FileCheck::CHECK_IS_TRUE(),  1, "CHECK_IS_TRUE";
is int Overload::FileCheck::CHECK_IS_FALSE(), 0, "CHECK_IS_FALSE";
is Overload::FileCheck::FALLBACK_TO_REAL_OP(), -1, "FALLBACK_TO_REAL_OP";

my @ops = qw{
  OP_FTRREAD
  OP_FTRWRITE
  OP_FTREXEC
  OP_FTEREAD
  OP_FTEWRITE
  OP_FTEEXEC
  OP_FTIS
  OP_FTSIZE
  OP_FTMTIME
  OP_FTCTIME
  OP_FTATIME
  OP_FTROWNED
  OP_FTEOWNED
  OP_FTZERO
  OP_FTSOCK
  OP_FTCHR
  OP_FTBLK
  OP_FTFILE
  OP_FTDIR
  OP_FTPIPE
  OP_FTSUID
  OP_FTSGID
  OP_FTSVTX
  OP_FTLINK
  OP_FTTTY
  OP_FTTEXT
  OP_FTBINARY
  OP_STAT
  OP_LSTAT
};

foreach my $op (@ops) {
    my $op_type = Overload::FileCheck->can($op)->();
    ok( $op_type, "$op_type: $op" );
}

is Overload::FileCheck::ST_DEV(),     0,  "ST_DEV";
is Overload::FileCheck::ST_INO(),     1,  "ST_INO";
is Overload::FileCheck::ST_MODE(),    2,  "ST_MODE";
is Overload::FileCheck::ST_NLINK(),   3,  "ST_NLINK";
is Overload::FileCheck::ST_UID(),     4,  "ST_UID";
is Overload::FileCheck::ST_GID(),     5,  "ST_GID";
is Overload::FileCheck::ST_RDEV(),    6,  "ST_RDEV";
is Overload::FileCheck::ST_SIZE(),    7,  "ST_SIZE";
is Overload::FileCheck::ST_ATIME(),   8,  "ST_ATIME";
is Overload::FileCheck::ST_MTIME(),   9,  "ST_MTIME";
is Overload::FileCheck::ST_CTIME(),   10, "ST_CTIME";
is Overload::FileCheck::ST_BLKSIZE(), 11, "ST_BLKSIZE";
is Overload::FileCheck::ST_BLOCKS(),  12, "ST_BLOCKS";
is Overload::FileCheck::STAT_T_MAX(), 13, "STAT_T_MAX";

done_testing;
