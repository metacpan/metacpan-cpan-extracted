package MooseX::JSONSchema;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Adding JSON Schema capabilities to your Moose class
$MooseX::JSONSchema::VERSION = '0.001';
use Moose::Exporter;
use Carp qw( croak );

Moose::Exporter->setup_import_methods(
  with_meta => [
    qw( array string object number integer boolean ),
    qw( json_schema_id json_schema_title json_schema_schema ),
  ],
  base_class_roles => ['MooseX::JSONSchema::Role'],
  class_metaroles => {
    class => ['MooseX::JSONSchema::MetaClassTrait'],
  },
  role_metaroles  => {
    role => ['MooseX::JSONSchema::MetaClassTrait'],
  },
);

sub json_schema_id { shift->json_schema_id(shift) }
sub json_schema_title { shift->json_schema_title(shift) }
sub json_schema_schema { shift->json_schema_schema(shift) }

sub array { add_json_schema_attribute( array => @_ ) }
sub string { add_json_schema_attribute( string => @_ ) }
sub object { add_json_schema_attribute( object => @_ ) }
sub number { add_json_schema_attribute( number => @_ ) }
sub integer { add_json_schema_attribute( integer => @_ ) }
sub boolean { add_json_schema_attribute( boolean => @_ ) }

sub add_json_schema_attribute {
  my ( $type, $meta, $name, $description, @args ) = @_;
  my $subtype;
  if ($type eq 'array' or $type eq 'object') {
    $subtype = shift @args;
  }
  my %opts = (
    json_schema_description => $description,
    json_schema_type => $type,
    predicate => 'has_'.$name,
    is => 'ro',
    isa => (
      $type eq 'string' ? 'Str'
      : $type eq 'number' ? 'Num'
      : $type eq 'integer' ? 'Int'
      : $type eq 'array' ? 'ArrayRef'
      : $type eq 'object' ? 'HashRef' : croak(__PACKAGE__.' can\'t handle type '.$type)),
    @args,
  );
  if ($opts{traits}) {
    push @{$opts{traits}}, 'MooseX::JSONSchema::AttributeTrait';
  } else {
    $opts{traits} = ['MooseX::JSONSchema::AttributeTrait'];
  }
  my %context = Moose::Util::_caller_info;
  $context{context} = 'moosex jsonschema attribute declaration';
  $context{type} = 'class';
  my @options = ( definition_context => \%context, %opts );
  my $attrs = ( ref($name) eq 'ARRAY' ) ? $name : [ ($name) ];
  $meta->add_attribute( $_, @options ) for @$attrs;
}

1;

__END__

=pod

=head1 NAME

MooseX::JSONSchema - Adding JSON Schema capabilities to your Moose class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package PersonClass;

  use Moose;
  use MooseX::JSONSchema;

  json_schema_title "A person";

  string first_name => "The first name of the person";
  string last_name => "The last name of the person";
  integer age => "Current age in years", json_schema_args => { minimum => 0, maximum => 200 };

  1;

  package CharacterClass;

  use Moose;
  use MooseX::JSONSchema;

  extends 'PersonClass';

  json_schema_title "Extended person";

  string job => "The job of the person";

  1;

  my $json_schema_json = PersonClass->meta->json_schema_json;

  my $person = PersonClass->new(
    first_name => "Peter",
    last_name => "Parker",
    age => 21,
  );

  my $json_schema_data_json = $person->json_schema_data_json;

=head1 DESCRIPTION

B<THIS API IS WORK IN PROGRESS>

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
