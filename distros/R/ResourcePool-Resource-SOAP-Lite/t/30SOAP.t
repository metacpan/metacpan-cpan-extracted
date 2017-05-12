#! /usr/bin/perl -w
#*********************************************************************
#*** t/30SOAP.t
#*** Copyright (c) 2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: 30SOAP.t,v 1.2 2003-02-22 17:07:48 mws Exp $
#*********************************************************************
use strict;
use Test;

use SOAP::Lite;
use ResourcePool;
use ResourcePool::Factory::SOAP::Lite;

BEGIN { plan tests => 2;};

# there shall be silence
#$SIG{'__WARN__'} = sub {};

my $f1 = ResourcePool::Factory::SOAP::Lite->new("proxy1");
my $pr1 = $f1->create_resource();
ok (! defined $pr1);

my $f2 = ResourcePool::Factory::SOAP::Lite->new(
	  "http://www.fatalmind.com/projects/ResourcePool/test/"
);
my $pr2 = $f2->create_resource();
ok (defined $pr2);


