package MongoDBx::Bread::Board::Container;
use Moose;
use Bread::Board;
use MongoDB;

extends 'Bread::Board::Container';

has '+name' => ( default => 'MongoDB' );
has 'host'  => ( is => 'ro', isa => 'Str', default => 'mongodb://localhost:27017' );

has 'additional_connection_params' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} }
);

has 'mongo_connection_class' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'MongoDB::Connection'
);

has 'database_layout' => (
    is       => 'ro',
    isa      => 'HashRef[ ArrayRef[ Str ] ]',
    required => 1,
);

sub BUILD {
    my $self = shift;

    my $conn_class = $self->mongo_connection_class;

    container $self => as {

        service 'host' => $self->host;

        service 'connection' => (
            lifecycle => 'Singleton',
            class     => $conn_class,
            block     => sub {
                my $s = shift;
                $conn_class->new(
                    host => $s->param('host'),
                    %{ $self->additional_connection_params }
                );
            },
            dependencies => [ 'host' ],
        );

        foreach my $db_name ( keys %{ $self->database_layout } ) {

            my $dbh = "${db_name}_dbh";

            service $dbh => (
                block => sub {
                    (shift)->param('connection')
                           ->get_database( $db_name );
                },
                dependencies => [ 'connection' ]
            );

            container $db_name => as {

                foreach my $coll_name ( @{ $self->database_layout->{ $db_name } } ) {
                    service $coll_name => (
                        block => sub {
                            (shift)->param( $dbh )
                                   ->get_collection( $coll_name );
                        },
                        dependencies => [ "../$dbh" ]
                    );
                }

            };
        }

    };
}

no Moose; no Bread::Board; 1;



=pod

=head1 NAME

MongoDBx::Bread::Board::Container

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use MongoDBx::Bread::Board::Container;

  # create a container

  my $c = MongoDBx::Bread::Board::Container->new(
      name            => 'MongoDB',
      host            => $HOST,
      database_layout => {
          test     => [qw[ foo bar ]],
          test_too => [qw[ baz gorch ]]
      }
  );

  # fetch the 'foo' collection
  # from the 'test' database
  my $foo = $c->resolve( service => 'MongoDB/test/foo');

  # get the MongoDB::Database
  # object for the 'test' db
  my $test = $c->resolve( service => 'MongoDB/test_dbh');

  # get the MongoDB::Connection
  # object used for all the above
  my $conn = $c->resolve( service => 'MongoDB/connection');

  # you can also create the container
  # within an existing Bread::Board config

  container 'MyProject' => as {

      # embed the Mongo container ...
      container(
          MongoDBx::Bread::Board::Container->new(
              name            => 'MyMongoDB',
              host            => $HOST,
              database_layout => {
                  test     => [qw[ foo bar ]],
                  test_too => [qw[ baz gorch ]]
              }
          )
      );

      # create services that depend
      # on the MongoDB container
      service 'foobar' => (
          class        => 'FooBar',
          dependencies => {
              collection => 'MyMongoDB/test/foo'
          }
      );
  };

=head1 DESCRIPTION

This is a subclass of L<Bread::Board::Container> which
can be used to provide services for your L<MongoDB> consuming
code. It manages your connection and additionally using the
C<database_layout> attribute can provide services to access
your databases and collections as well.

=head1 ATTRIBUTES

=head2 name

This is inherited from L<Bread::Board::Container>, this
defaults to 'MongoDB' in this container.

=head2 host

The hostname passed to L<MongoDB::Connection>, this
defaults to 'mongodb://localhost:27017'.

=head2 additional_connection_params

If you want to pass additional parameters to the
L<MongoDB::Connection> constructor, just supply them
here and they will get merged in with the C<host> and
C<port> params.

=head2 mongo_connection_class

This is the name of the MongoDB connection class, it
default to MongoDB::Connection, which is what you want
to use most of the time, but if you want something else
then you put it here.

=head2 database_layout

This is a data structure that represents the databases
and collections you want to access. It is a HASH ref
where the keys are the database names and the values
are ARRAY refs of collection names. The set of
sub-containers and services will then be created based
on this information. See the C<SYNOPSIS> and the tests
for more detailed examples.

This attribute is required.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
# ABSTRACT: An easy to use Bread::Board container for MongoDB

