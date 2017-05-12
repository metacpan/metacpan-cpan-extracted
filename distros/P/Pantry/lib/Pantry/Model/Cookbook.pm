use v5.14;
use warnings;

package Pantry::Model::Cookbook;

# ABSTRACT: Pantry data model for Chef cookbooks
our $VERSION = '0.012'; # VERSION

use Moose 2;
use MooseX::Types::Path::Class::MoreCoercions qw/Dir/;
use Path::Class;
##use List::AllUtils qw/uniq first/;
##use Pantry::Model::Util qw/hash_to_dot dot_to_hash/;
use namespace::autoclean;

#--------------------------------------------------------------------------#
# Chef role attributes
#--------------------------------------------------------------------------#

has _path => (
  is        => 'ro',
  reader    => 'path',
  isa       => Dir,
  coerce    => 1,
  predicate => 'has_path',
);

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

##has description => (
##  is => 'ro',
##  isa => 'Str',
##  lazy_build => 1,
##);
##
##sub _build_description {
##  my $self = shift;
##  return "The " . $self->name . " cookbook";
##}


sub create_boilerplate {
  my ($self) = @_;
  my @dirs = qw(
    attributes
    definitions
    files
    libraries
    providers
    recipes
    resources
    templates
    templates/default
  );
  my @files = qw(
    README.rdoc
    metadata.rb
    recipes/default.rb
    attributes/default.rb
  );
  for my $d ( @dirs ) {
    dir($self->path, $d)->mkpath;
  }
  for my $f ( @files ) {
    file($self->path, $f)->touch;
  }
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::Model::Cookbook - Pantry data model for Chef cookbooks

=head1 VERSION

version 0.012

=head1 DESCRIPTION

Under development.

=head1 METHODS

=head2 create_boilerplate

Creates boilerplate files under the path attribute

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
