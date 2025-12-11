package URI::bolt;
 
our $VERSION = '0.5001';

require URI::_server;
@ISA=qw(URI::_server);
 
use strict;
use warnings;
 
sub default_port { 7687 }
 
1;
