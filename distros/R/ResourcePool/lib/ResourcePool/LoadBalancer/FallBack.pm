#*********************************************************************
#*** ResourcePool::LoadBalancer::FallBack
#*** Copyright (c) 2002,2003 by Markus Winand <mws@fatalmind.com>
#*** $Id: FallBack.pm,v 1.12 2013-04-16 10:14:44 mws Exp $
#*********************************************************************
package ResourcePool::LoadBalancer::FallBack;

use vars qw($VERSION @ISA);
use ResourcePool::LoadBalancer::FailBack;

$VERSION = "1.0107";
push @ISA, "ResourcePool::LoadBalancer::FailBack";

# just a synonym, nothing changes

1;
