package URI::bolt;
 
require URI::_server;
@ISA=qw(URI::_server);
 
use strict;
 
sub default_port { 7687 }
 
1;
