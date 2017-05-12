#! /usr/bin/perl -w
#*********************************************************************
#*** t/11Resource.t
#*** Copyright (c) 2002 by Markus Winand <mws@fatalmind.com>
#*** $Id: 11Resource.t,v 1.1 2002-08-29 07:48:23 mws Exp $
#*********************************************************************
use strict;
use Test;

use ResourcePool;
use ResourcePool::Resource;

BEGIN { plan tests => 2; };

my $r = ResourcePool::Resource->new();
ok($r->precheck());
ok($r->postcheck());
