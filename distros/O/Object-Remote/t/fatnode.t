use strict;
use warnings;

use strictures 1;
use Test::More;

plan tests => 1;

require Object::Remote::FatNode;
my $data =  do {
    no warnings 'once';
    $Object::Remote::FatNode::DATA;
};

ok $data !~ m|MODULELOADER_HOOK|mx,'MODULELOADER_HOOK should not be in the fatpack.';
