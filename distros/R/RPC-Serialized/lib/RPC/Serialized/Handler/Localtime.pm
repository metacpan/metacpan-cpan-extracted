#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/Handler/Localtime.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::Handler::Localtime;
{
  $RPC::Serialized::Handler::Localtime::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Handler';

sub invoke {
    my $self = shift;
    my $time = shift;

    $time = time unless defined $time;
    return scalar localtime($time);
}

1;

