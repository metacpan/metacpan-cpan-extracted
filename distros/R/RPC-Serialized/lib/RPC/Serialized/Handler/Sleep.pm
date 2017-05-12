#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/Handler/Sleep.pm $
# $LastChangedRevision: 1322 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::Handler::Sleep;
{
  $RPC::Serialized::Handler::Sleep::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Handler';

sub invoke {
    my $self = shift;
    my $seconds = shift;
    return [] if $seconds !~ m/^\d+$/;
    sleep $seconds;
    return [$seconds];
}

1;

