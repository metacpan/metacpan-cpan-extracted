package MooseX::JSONSchema::AttributeTrait;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Trait for JSON Schema attributes
$MooseX::JSONSchema::AttributeTrait::VERSION = '0.001';
use Moose::Role;

has json_schema_description => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_json_schema_description',
);

has json_schema_type => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_json_schema_type',
);

has json_schema_args => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);
sub _build_json_schema_args {{}}

has json_schema_property_data => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);
sub _build_json_schema_property_data {
  my ( $self ) = @_;
  return {
    type => $self->json_schema_type,
    description => $self->json_schema_description,
    %{$self->json_schema_args},
  };
}

1;

__END__

=pod

=head1 NAME

MooseX::JSONSchema::AttributeTrait - Trait for JSON Schema attributes

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package OtherClass;

  use Moose;
  use MooseX::JSONSchema;

  ...

  has something => (
    traits => [qw( MooseX::JSONSchema::AttributeTrait )],
    json_schema_description => $description,
    json_schema_type => 'string',
    predicate => 'has_something',
    is => 'ro',
    isa => 'Str',
  );

=head1 SUPPORT

Repository

  https://github.com/Getty/perl-moosex-jsonschema
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/perl-moosex-jsonschema/issues

=cut

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/perl-moosex-jsonschema>

  git clone https://github.com/Getty/perl-moosex-jsonschema.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
