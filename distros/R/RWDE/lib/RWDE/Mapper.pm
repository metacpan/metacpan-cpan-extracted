package RWDE::Mapper;

use strict;
use warnings;

use RWDE::Gearman::Client;

use vars qw($AUTOLOAD);
use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 536 $ =~ /(\d+)/;

=pod

=head1 RWDE::Mapper

Object to handle mapping of RPC namespaces. The mapping object translates the call from 
the local, imported class to the remote namespace.

This class is present in order to avoid namespace conflicts while building RPC interfaces,
which in our case is Gearman. Specifically it is very easy to cause namespace collisions under
these circumstances, so some care is needed while implementing these types of calls.

=cut

=head2 AUTOLOAD

Object to handle mapping of namespaces. The mapping object translates the call from 
the local, imported class to the remote namespace.

The calling convention is $local::$remote -> $remote::$remote

=cut

sub AUTOLOAD {
  my ($self, $params) = @_;

  $AUTOLOAD =~ m/.*::(.*)::(.*)/;

  my $namespace=$1;
  my $method=$2;

  $$params{method} = $1 .'::' . $1 .'::'.$method;
  
  return RWDE::Gearman::Client->Do_task($params);
}

=head2 DESTROY()

Do nothing. This is here to avoid sending the DESTROY request over RPC

=cut

sub DESTROY {

}

1;
