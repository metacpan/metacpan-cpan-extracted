#!/usr/bin/perl

use strict;
use lib '../lib';
use lib 'lib';
use OS390::IEBUtils;
use Test::More 'no_plan';


open my $output, '>/tmp/out' or die $!;


my $obj = OS390::IEBUtils::IEBPTPCH->new($output);
$obj->{debug} = 1;
ok(defined($obj), 'object was defined');

# valid membernames
ok($obj->_validMemberName('X23456'));
ok($obj->_validMemberName('$23456'));

# invalid membernames
ok(not $obj->_validMemberName('123456'));
ok(not $obj->_validMemberName('x234567890'));
ok(not $obj->_validMemberName('\abc'));
ok(not $obj->_validMemberName('/abc'));
ok(not $obj->_validMemberName(' bc'));






