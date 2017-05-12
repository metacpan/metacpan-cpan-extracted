#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/ACL/Operation.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::ACL::Operation;
{
  $RPC::Serialized::ACL::Operation::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use RPC::Serialized::Exceptions;

sub new {
    my $class = shift;
    my $name  = shift;

    throw_app 'Operation name not specified'
        unless defined $name;

    return bless {
        NAME => $name,
    }, $class;
}

sub name {
    my $self = shift;
    return $self->{NAME};
}

sub match {
    my $self      = shift;
    my $operation = shift;

    return 1 if $self->name eq 'ALL';
    return (defined $operation and $operation eq $self->name);
}

1;

