#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib','../t/lib','t/lib';

use Object::GlobalContainer 'objcon';


use Test::More tests => 1;


my $OC = Object::GlobalContainer->new();

my $storename = $OC->storename;

my $param;

$param->{name}='ertzu';

objcon->class('c/foo','Local::Foo',%$param);

is( objcon->get('c/foo')->test(), '42ertzu');




1;
