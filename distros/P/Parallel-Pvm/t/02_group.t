#!perl -w
#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision: 1.7 $
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb 22 23:18:12 2001
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Feb 23 03:57:11 2001
# Language        : CPerl
# 
# (C) Copyright 2001, UUNET Deutschland GmbH, Germany
# 

use strict;
use Test;
BEGIN { plan tests => 9 }

use Parallel::Pvm;

my $inum = Parallel::Pvm::joingroup("foo");
ok($inum >= 0);

my $onum = Parallel::Pvm::lvgroup("foo");
ok($onum >= 0);
#ok($inum == $onum);

my $qnum = Parallel::Pvm::lvgroup("foo");
ok($qnum < 0);

$inum = Parallel::Pvm::joingroup("foo");
Parallel::Pvm::initsend(PvmDataRaw);
Parallel::Pvm::pack("Hello");
my $info = Parallel::Pvm::bcast("foo",17);
ok($info == -21);               # nobody listening

$info = Parallel::Pvm::freezegroup("foo");
ok($info >= 0);

$info = Parallel::Pvm::barrier("foo", 1);
ok($info >= 0);

$info = Parallel::Pvm::getinst("foo", -1); # -1 seems to be "any"
ok($info >= 0);

$info = Parallel::Pvm::gettid("foo", $inum);
ok($info >= 0);

$info = Parallel::Pvm::gsize("foo");
ok($info == 1);
