#!/usr/bin/perl
# Andrew Purshottam Jun 2004

use warnings;
use strict;
use diagnostics;
use POE;
use POE::Filter::Stream;
use POE::Filter::Line;
use POE::Component::Proxy::TCP;
$|++;  

POE::Component::Proxy::TCP->new
  (Alias => "ProxyServerSessionAlias",
   Port               => 4000,
   OrigPort           => 5000,
   OrigAddress        => "localhost",
   DataFromClient    => sub {print "From client:", shift(), "\n";},
   DataFromServer    => sub {print "From server:", shift(), "\n";},
   RemoteClientFilter => "POE::Filter::Stream",
   RemoteServerOutputFilter => "POE::Filter::Stream",
   RemoteServerInputFilter => "POE::Filter::Stream"
  );

$poe_kernel->run();
exit 0;
 

