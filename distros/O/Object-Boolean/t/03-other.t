#!perl 

use Test::More tests => 14;
use strict;

use Object::Boolean::YesNo True => { -as => 'Yes'}, False => { -as => 'No' };
use Object::Boolean qw/True False/;

{
    my $a = Object::Boolean->new(1);
    my $b = Object::Boolean::YesNo->new(1);

    ok $b    == $a,      'two true objects are equal';
    ok $a    eq True,    'a is true';
    ok $b    eq Yes,     'b is yes';
    ok !$b   eq No,      'not b is no';
    ok !$b   eq 'No',    'not is "No"';
    ok Yes   eq 'Yes',   'yes is yes';
    ok No    eq 'No',    'no is no';
    ok True  eq 'true',  'true is true';
    ok False eq 'false', 'false is false';
}

{
    my $a = Object::Boolean::YesNo->new(0);
    my $b = Object::Boolean::YesNo->new('No');

    my $c = Object::Boolean::YesNo->new(1);
    my $d = Object::Boolean::YesNo->new('hippopotamus');

    ok $a eq 'No', 'no';
    ok !$a eq 'Yes', 'yes';
    ok $c eq 'Yes', 'yes';
    ok $d eq 'Yes', 'yes';
    ok !$d eq 'No', 'no';
}

