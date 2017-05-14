package Swagger::Generator::DumpSchema;
  use Moose;
  use Data::Dumper;

  has swagger => (is => 'ro', isa => 'Swagger::Schema');

  sub process {
    my $self = shift;
    print Dumper($self->swagger);
  }

1;
