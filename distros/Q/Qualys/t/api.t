#!/usr/bin/perl


use strict;
use blib;
use Test::More tests => 9;
use vars qw(@API);
use Qualys;


my $qapi = new Qualys;


isa_ok( $qapi , 'Qualys');

for(sort @API){can_ok($qapi,$_);}

BEGIN {

@API = qw(
get_basic_credentials
userid
passwd
server
api_path
clear_attribs
attribs
connect_to
);


}
