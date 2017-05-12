#!/usr/bin/env perl
# Serialize variables when sprintid
use warnings;
use strict;

use Test::More tests => 16;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

is($f->sprinti("#{v}#", v => undef),  '#undef#', 'UNDEF');
is($f->sprinti("#{v}#", v => ''),     '##'     , 'empty string');
is($f->sprinti("#{v}#", v => 42),     '#42#'   , 'string');
is($f->sprinti("#{v}#", v => [12,13]),'#12, 13#', 'ARRAY');
is($f->sprinti("#{v}#", v => [14,15], _join => ' '),'#14 15#');
{  local $" = ':';
   is($f->sprinti("#{v}#", v => [16,17], _join => $"), '#16:17#');
}
is($f->sprinti("#{v}#", v => {a => 3, b => 5})
   ,'#a => 3, b => 5#', 'HASH');

is($f->sprinti("#{v}#", v => sub {18}),'#18#', 'CODE');
is($f->sprinti("#{v}#", v => sub {sub {19}}),'#19#', 'CODE CODE');

is($f->sprinti("#{v}#", v => \50),'#50#', 'SCALAR');
is($f->sprinti("#{v}#", v => \undef),'#undef#', 'SCALAR undef');

my $g = String::Print->new
  ( serializers =>
     [ UNDEF => sub {'(undef)'}
     , ARRAY => sub {join '|',  reverse @{$_[1]} }
     , MyObj => \&name_in_reverse
     ]
  );
isa_ok($g, 'String::Print');
is($g->sprinti("#{v}#", v => undef),  '#(undef)#');
is($g->sprinti("#{v}#", v => [8..13]),'#13|12|11|10|9|8#');

#
### Object interpolation
#    used as example in man-page
#

{   package MyObj;
    sub name() {shift->{name}}
}
my $obj = bless {name => 'my-name'}, 'MyObj';
is($g->sprinti("#{v}#", v => $obj),'#eman-ym#');

sub name_in_reverse($$$)
{   my ($formatter, $object, $args) = @_;
    # the $args are all parameters to be filled-in
    scalar reverse $object->name;
}

