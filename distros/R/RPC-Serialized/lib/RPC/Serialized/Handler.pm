#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/Handler.pm $
# $LastChangedRevision: 1326 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::Handler;
{
  $RPC::Serialized::Handler::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

sub invoke {
    my $self = shift;
    return;
}

sub target {
    my $self = shift;
    return undef;
}

1;

