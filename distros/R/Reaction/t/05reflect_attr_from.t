package TestMe2;
use strict;
use warnings;
use Reaction::Class;
use Reaction::Types::DateTime;

has id         => (is => 'ro', required => 1, isa => 'Int');
has username   => (is => 'rw', required => 1, isa => 'NonEmptySimpleStr');
has created_d  => (is => 'rw', required => 1, isa => 'DateTime');

1;

package TestMe;
use strict;
use warnings;
use Reaction::Class;

reflect_attributes_from('TestMe2' => qw(id username created_d));

1;

package main;
use strict;
use warnings;
use Data::Dumper;
use Test::More;

plan tests => 1;

my @test_list  = TestMe->meta->get_attribute_list;
my @test2_list = TestMe2->meta->get_attribute_list;
is_deeply(\@test_list, \@test2_list, "Attribute lists match");

1;
