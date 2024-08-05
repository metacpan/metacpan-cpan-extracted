package MooseX::JSONSchema::MetaClassTrait;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Trait for meta classes having a JSON Schema
$MooseX::JSONSchema::MetaClassTrait::VERSION = '0.001';
use Moose::Role;
use JSON::MaybeXS;

has json_schema_id => (
  is => 'rw',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_json_schema_id {
  my ( $self ) = @_;
  my $class = lc($self->name);
  $class =~ s/::/./g;
  return 'https://json-schema.org/perl.'.$class.'.schema.json';
}

has json_schema_schema => (
  is => 'rw',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_json_schema_schema {
  my ( $self ) = @_;
  return 'https://json-schema.org/draft/2020-12/schema';
}

has json_schema_title => (
  is => 'rw',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_json_schema_title {
  my ( $self ) = @_;
  my $class = ref $self;
  $class =~ s/::/ /g;
  return join(' ',map { ucfirst } split(/\s+/, $class));
}

has json_schema_data => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);
sub _build_json_schema_data {
  my ( $self ) = @_;
  return {
    '$id' => $self->json_schema_id,
    '$schema' => $self->json_schema_schema,
    title => $self->json_schema_title,
    type => 'object',
    properties => $self->json_schema_properties,
  };
}

has json_schema_properties => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);
sub _build_json_schema_properties {
  my ( $self ) = @_;
  my @schema_attributes = grep { $_->does('MooseX::JSONSchema::AttributeTrait') } $self->get_all_attributes;
  return { map { $_->name, $_->json_schema_property_data } @schema_attributes };
}

sub json_schema_json {
  my ( $self, %args ) = @_;
  my $data = $self->json_schema_data;
  my $json = JSON::MaybeXS->new(
    utf8 => 1,
    canonical => 1,
    %args,
  );
  return $json->encode($data);
}

1;

__END__

=pod

=head1 NAME

MooseX::JSONSchema::MetaClassTrait - Trait for meta classes having a JSON Schema

=head1 VERSION

version 0.001

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
