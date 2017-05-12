#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 26 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test MooseX::AttributeTree on a simple class
#---------------------------------------------------------------------

use Test::More 0.88 tests => 140; # done_testing

use MooseX::AttributeTree;

#=====================================================================
# Class for testing:

{
  package My_Test;

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
    traits => [qw/TreeInherit/],
  );

  has ro_value => (
    is     => 'ro',
    predicate => 'has_ro_value',
    clearer   => 'clear_ro_value',
    traits => [qw/TreeInherit/],
  );
}

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

  $init->{parent} = $parent;
  my $node = $node{$name} = My_Test->new($init);

  foreach my $child (@$data) {
    build_hierarchy($child, $node);
  } # end foreach $child
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

    is($node->value,    "$value value",       "$testName $name value");
    is($node->has_value, $name eq lc $value,  "$testName $name has_value");
    is($node->ro_value, "$ro_value ro_value", "$testName $name ro_value");
    is($node->has_ro_value, $name eq lc $ro_value,
       "$testName $name has_ro_value");
  } # end while @_
} # end check_values

check_values('initial', @values);

#---------------------------------------------------------------------

$node{root}->value('ROOT value');

for my $i (0 .. $#values) {
  $values[$i] =~ s/root/ROOT/ if $i % 3 == 1;
}

check_values('root change', @values);

#---------------------------------------------------------------------
$node{a}->value('A value');

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
$node{aa}->clear_value;

for my $i (0 .. $#values) {
  $values[$i] =~ s/^aa$/A/ if $i % 3 == 1;
}

check_values('aa cleared', @values);

#---------------------------------------------------------------------
$node{b}->clear_ro_value;

for my $i (0 .. $#values) {
  $values[$i] =~ s/^b$/root/ if $i % 3 == 2;
}

check_values('b cleared', @values);

done_testing;
