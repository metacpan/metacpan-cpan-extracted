package MooseX::Role::DBIx::Connector;
use MooseX::Role::Parameterized;
use DBIx::Connector;

our $VERSION = '0.11';
$VERSION = eval $VERSION;


parameter 'connection_name' => qw(
    is        ro
    isa       Str
    default   db
   );


parameter 'connection_description' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
   );   __PACKAGE__->meta->parameters_metaclass->add_method(
   _build_connection_description => sub {
       my $n = shift->connection_name;
       $n =~ s/_/ /g;
       return $n;
   });


parameter 'accessor_options' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);


role {

    my $p        = shift;
    my $conn     = $p->connection_name;
    my $desc     = $p->connection_description;
    my $opts     = $p->accessor_options;

    has "${conn}_dsn" => (
        documentation => "DBI dsn for connecting to the $desc",
        isa           => 'Str',
        is            => 'ro',
        required      => 1,
        @{ $opts->{$conn.'_dsn'} || [] },
       );
    has "${conn}_user" => (
        documentation  => "username for connecting to the $desc",
        isa            => 'Str',
        is             => 'ro',
        @{ $opts->{"${conn}_user"} || [] },
       );
    has "${conn}_password" => (
        documentation => "password for connecting to the $desc",
        isa           => 'Str',
        is            => 'ro',
        @{ $opts->{"${conn}_password"} || [] },
       );

    has "${conn}_attrs" => (
        documentation => "hashref of DBI attributes for connecting to $desc",
        is            => 'ro',
        isa           => 'HashRef',
        default       => sub { {} },
        @{ $opts->{"${conn}_attrs"} || [] },
       );

    has "${conn}_conn" => (
        is         => 'ro',
        isa        => 'DBIx::Connector',
        lazy_build => 1,
        @{ $opts->{"${conn}_conn"} || [] },
       );

    method "_build_${conn}_conn" => sub {
        my ($self) = @_;

        no strict 'refs';

        return DBIx::Connector->new(
            $self->{"${conn}_dsn"},
            $self->{"${conn}_user"},
            $self->{"${conn}_password"},
            $self->{"${conn}_attrs"},
           );
    };

};


__END__


=head1 NAME

MooseX::Role::DBIx::Connector - give your Moose class DBIx::Connector powers

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  with 'MooseX::Role::DBIx::Connector';

  package main;

  my $c = MyClass->new(
      db_dsn  => 'dbi:Pg:dbname=foo;host=bar',
      db_user => 'mikey',
      db_password => 'seekrit',
      db_attrs => { Foo => 'Bar' },
     );

  $c->db_conn->dbh->selectall_arrayref( ... );

  $c->db_conn->txn( fixup => sub { ... } );


  ### more advanced usage

  package BigClass;
  use Moose;
  with 'MooseX::Role::DBIx::Connector' => { connection_name => 'itchy'    };
  with 'MooseX::Role::DBIx::Connector' => { connection_name => 'scratchy' };

  package main;

  my $c = BigClass->new(
      itchy_dsn  => 'dbi:Pg:dbname=foo;host=bar',
      itchy_user => 'mikey',
      itchy_password => 'seekrit',

      scratchy_dsn   => 'dbi:SQLite:dbname=somefile',
     );

  $c->itchy_conn->dbh->selectall_arrayref( ... );
  $c->scratchy_conn->txn( fixup => sub { ... } );

=head1 DESCRIPTION

Generic parameterized Moose role to give your class accessors to
manage one or more L<DBIx::Connector> connections.

=head1 ROLE PARAMETERS

=head1 connection_name

Name for this connection, which is the prefix for all the generated
accessors.  Default 'db', which means that you get the accessors
C<db_dsn>, C<db_user>, C<db_password>, C<db_attrs>, and C<db_conn>.

=head1 connection_description

Plaintext description of this connection.  Only used in generating
C<documentation> for each of the generated accessors.

=head1 accessor_options

Hashref of additional options to pass to the generated accessors, e.g.

  package MyClass;
  use Moose;
  with 'MooseX::Role::DBIx::Connector' => {
    connection_name  => 'itchy',
    accessor_options => { 'itchy_dsn'  => [ traits => ['GetOpt'], ],
                          'itchy_user' => [ default => 'minnie_the_moocher' ],
                        }
  };

=head1 ATTRIBUTES

=head2 (connection_name)_conn

Get a L<DBIx::Connector> connection object for the given connection info.

=head2 (connection_name)_dsn

L<DBI> DSN for your connection.  Required.

=head2 (connection_name)_user

Username for the connection.

=head2 (connection_name)_password

Password for the connection.

=head2 (connection_name)_attrs

Hashref of L<DBI> attributes for the connection.  Passed to
L<DBIx::Connector>, which passes them to L<DBI>'s connect()

=head1 AUTHOR

Robert Buels, <rmb32@cornell.edu>
