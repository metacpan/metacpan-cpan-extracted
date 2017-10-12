package Apache::AwSOAP;

use strict;
use Apache;
use SOAP::Transport::ActiveWorks::Lite;

my $server = SOAP::Transport::ActiveWorks::Lite::Apache
   -> dispatch_to( '' );


sub handler { $server->handler(@_); }

1;
__END__
