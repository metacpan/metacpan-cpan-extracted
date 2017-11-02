# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Pootle-Client.

package Pootle::Filters::Intersection;

use Modern::Perl '2015';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
use feature 'signatures'; no warnings "experimental::signatures";
use Carp::Always;
use Try::Tiny;
use Scalar::Util qw(blessed);

=head2 Pootle::Filters::Intersection

Represents an intersection of two Pootle::Resource::* objects based on a common attribute

=cut

use Params::Validate qw(:all);

use Pootle::Logger;
my $l = bless({}, 'Pootle::Logger'); #Lazy load package logger this way to avoid circular dependency issues with logger includes from many packages

sub new($class, @params) {
  $l->debug("Initializing ".__PACKAGE__." with parameters: ".$l->flatten(@params)) if $l->is_debug();
  my %self = validate(@params, {
    obj1           => 1, #eg. a Pootle::Resource::Language-object,
    obj1Attribute  => 1, #eg. "translationProjects",
    obj2           => 1, #eg. a Pootle::Resource::Project-object,
    obj2Attribute  => 1, #eg. "translationProjects",
    attributeValue => 1, #eg. "/api/v1/translation-projects/1178/"
  });
  my $s = bless(\%self, $class);

  return $s;
}

sub obj1($s)           { return $s->{obj1} }
sub obj1Attribute($s)  { return $s->{obj1Attribute} }
sub obj2($s)           { return $s->{obj2} }
sub obj2Attribute($s)  { return $s->{obj2Attribute} }
sub attributeValue($s) { return $s->{attributeValue} }

=head2 Accessors

=over 4

=item B<obj1>

=item B<obj1Attribute>

=item B<obj2>

=item B<obj2Attribute>

=item B<attributeValue>

The common value for both objects

=cut

1;
