package Apache::AwSOAP;

use strict;
use Apache;
use SOAP::Transport::ACTIVEWORKS;

my $server = SOAP::Transport::ACTIVEWORKS::Apache
   -> dispatch_to( '' );


sub handler { $server->handler(@_); }

1;
__END__
