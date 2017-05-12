#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/AuthzHandler.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::AuthzHandler;
{
  $RPC::Serialized::AuthzHandler::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub check_authz {
    my $self = shift;
    return 1;
}

1;

