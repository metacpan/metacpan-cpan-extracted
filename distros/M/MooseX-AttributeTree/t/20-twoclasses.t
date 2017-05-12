#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 02 Jun 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test MooseX::AttributeTree on container/leaf classes
#---------------------------------------------------------------------

use Test::More 0.88 tests => 140; # done_testing

use MooseX::AttributeTree;

#=====================================================================
# Classes for testing:

{
  package My_Container;

  use Moose;
  use MooseX::AttributeTree ();

  has parent => (
    is       => 'rw',
    isa      => 'Maybe[Object]',
    weak_ref => 1,
  );

  has values => (
    is     => 'ro',
    isa    => 'HashRef',
  );

  sub get_value
  {
    my ($self, $attribute) = @_;

    # See if we have the attribute:
    my $values = $self->values;

    return $values->{$attribute} if $values and exists $values->{$attribute};

    # We don't have it, ask our parent:
    my $parent = $self->parent;
    return ($parent ? $parent->get_value($attribute) : undef);
  } # end get_value
} # end My_Container

#---------------------------------------------------------------------
{
  package My_Leaf;

  use Moose;
  use MooseX::AttributeTree ();

  has parent => (
    is       => 'rw',
    isa      => 'Maybe[Object]',
    weak_ref => 1,
  );

  has value => (
    is     => 'rw',
    predicate => 'has_value',
    clearer   => 'clear_value',
    traits   => [ TreeInherit => {
      fetch_method => 'get_value',
    } ],
  );

  has ro_value => (
    is     => 'ro',
    predicate => 'has_ro_value',
    clearer   => 'clear_ro_value',
    traits   => [ TreeInherit => {
      fetch_method => 'get_value',
      default      => 'default ro_value',
    } ],
  );
} # end My_Leaf

#=====================================================================
# Create the node hierarchy:

my $hierarchy = [
  root => { value => 'root value', ro_value => 'root ro_value' },
  [ a => {},
    [ aa => { value => 'aa value' },
      [ aaa => { ro_value => 'aaa ro_value' } ],
      [ aab => { value => 'aab value' } ] ],
    [ ab => {} ] ],
  [ b => { value => 'b value', ro_value => 'b ro_value' } ],
];

my @values = qw(
  root root root
  a    root root
  aa   aa   root
  aaa  aa   aaa
  aab  aab  root
  ab   root root
  b    b    b
);

my %node;

sub build_hierarchy
{
  my ($data, $parent) = @_;

  my $name = shift @$data;
  my $init = shift @$data;

  if (@$data) {
    # Create a container node:
    my $node = $node{$name} = My_Container->new(parent => $parent,
                                                values => $init);

    foreach my $child (@$data) {
      build_hierarchy($child, $node);
    } # end foreach $child
  } else {
    # Create a leaf node:
    $init->{parent} = $parent;
    $node{$name} = My_Leaf->new($init);
  } # end else leaf node
} # end build_hierarchy

build_hierarchy($hierarchy);

#=====================================================================
# Check values:

sub check_values
{
  my $testName = shift;

  while (@_) {
    my $name     = shift;
    my $value    = shift;
    my $ro_value = shift;

    my $node = $node{$name};

    if ($node->isa('My_Container')) {
      is($node->get_value('value'), "$value value", "$testName $name value");
      is(defined($node->values->{value}), $name eq lc $value,
         "$testName $name has_value");
      is($node->get_value('ro_value'),
         ($ro_value eq 'default' ? undef : "$ro_value ro_value"),
         "$testName $name ro_value");
      is(defined($node->values->{ro_value}), $name eq lc $ro_value,
         "$testName $name has_ro_value");
    } else {
      is($node->value,    "$value value",       "$testName $name value");
      is($node->has_value, $name eq lc $value,  "$testName $name has_value");
      is($node->ro_value, "$ro_value ro_value", "$testName $name ro_value");
      is($node->has_ro_value, $name eq lc $ro_value,
         "$testName $name has_ro_value");
    } # end else leaf node
  } # end while @_
} # end check_values

check_values('initial', @values);

#---------------------------------------------------------------------

$node{root}->values->{value} = 'ROOT value';

for my $i (0 .. $#values) {
  $values[$i] =~ s/root/ROOT/ if $i % 3 == 1;
}

check_values('root change', @values);

#---------------------------------------------------------------------
$node{a}->values->{value} = 'A value';

@values = qw(
  root ROOT root
  a    A    root
  aa   aa   root
  aaa  aa   aaa
  aab  aab  root
  ab   A    root
  b    b    b
);

check_values('a set', @values);

#---------------------------------------------------------------------
delete $node{aa}->values->{value};

for my $i (0 .. $#values) {
  $values[$i] =~ s/^aa$/A/ if $i % 3 == 1;
}

check_values('aa cleared', @values);

#---------------------------------------------------------------------
delete $node{root}->values->{ro_value};
$node{b}->clear_ro_value;

for my $i (0 .. $#values) {
  $values[$i] =~ s/^(?:root|b)$/default/ if $i % 3 == 2;
}

check_values('b cleared', @values);

done_testing;
