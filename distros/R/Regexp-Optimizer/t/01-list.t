#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Regexp::List;
use Test::More;

plan tests => 1;
my $rl = Regexp::List->new();
my $ra = Regexp::Assemble->new();
my @list = ( 'ab+c', 'ab+-', 'a\w\d+', 'a\d+' );
$ra->add(@list);
is $rl->list2re(@list), $ra->re, 'Regexp::Assemble';
