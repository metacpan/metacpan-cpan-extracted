use strict;
use warnings;
use Test::More;

package MyClass;
use Moose;
use MooseX::Types::Varchar qw/ Varchar /;
use Moose::Util::TypeConstraints;

subtype 'ThisType', as Varchar[20];

has 'attr1' => (is => 'rw', required => 1, isa => 'ThisType');

package main;

eval {
        my $obj = MyClass->new( attr1 => 'This is over twenty characters long.' );
};
ok($@);

eval {
        my $obj = MyClass->new( attr1 => 'This isn\'t.' );
};
ok(!$@, 'short-enough string');

done_testing;
