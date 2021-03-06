package Paws::RDS::ConnectionPoolConfiguration;
  use Moose;
  has ConnectionBorrowTimeout => (is => 'ro', isa => 'Int');
  has InitQuery => (is => 'ro', isa => 'Str');
  has MaxConnectionsPercent => (is => 'ro', isa => 'Int');
  has MaxIdleConnectionsPercent => (is => 'ro', isa => 'Int');
  has SessionPinningFilters => (is => 'ro', isa => 'ArrayRef[Str|Undef]');
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ConnectionPoolConfiguration

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::RDS::ConnectionPoolConfiguration object:

  $service_obj->Method(Att1 => { ConnectionBorrowTimeout => $value, ..., SessionPinningFilters => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::RDS::ConnectionPoolConfiguration object:

  $result = $service_obj->Method(...);
  $result->Att1->ConnectionBorrowTimeout

=head1 DESCRIPTION

This is prerelease documentation for the RDS Database Proxy feature in
preview release. It is subject to change.

Specifies the settings that control the size and behavior of the
connection pool associated with a C<DBProxyTargetGroup>.

=head1 ATTRIBUTES


=head2 ConnectionBorrowTimeout => Int

  The number of seconds for a proxy to wait for a connection to become
available in the connection pool. Only applies when the proxy has
opened its maximum number of connections and all connections are busy
with client sessions.

Default: 120

Constraints: between 1 and 3600, or 0 representing unlimited


=head2 InitQuery => Str

  One or more SQL statements for the proxy to run when opening each new
database connection. Typically used with C<SET> statements to make sure
that each connection has identical settings such as time zone and
character set. For multiple statements, use semicolons as the
separator. You can also include multiple variables in a single C<SET>
statement, such as C<SET x=1, y=2>.

Default: no initialization query


=head2 MaxConnectionsPercent => Int

  The maximum size of the connection pool for each target in a target
group. For Aurora MySQL, it is expressed as a percentage of the
C<max_connections> setting for the RDS DB instance or Aurora DB cluster
used by the target group.

Default: 100

Constraints: between 1 and 100


=head2 MaxIdleConnectionsPercent => Int

  Controls how actively the proxy closes idle database connections in the
connection pool. A high value enables the proxy to leave a high
percentage of idle connections open. A low value causes the proxy to
close idle client connections and return the underlying database
connections to the connection pool. For Aurora MySQL, it is expressed
as a percentage of the C<max_connections> setting for the RDS DB
instance or Aurora DB cluster used by the target group.

Default: 50

Constraints: between 0 and C<MaxConnectionsPercent>


=head2 SessionPinningFilters => ArrayRef[Str|Undef]

  Each item in the list represents a class of SQL operations that
normally cause all later statements in a session using a proxy to be
pinned to the same underlying database connection. Including an item in
the list exempts that class of SQL operations from the pinning
behavior.

Default: no session pinning filters



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

