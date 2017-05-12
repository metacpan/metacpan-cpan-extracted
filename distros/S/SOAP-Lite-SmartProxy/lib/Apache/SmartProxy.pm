package Apache::SmartProxy;

use SOAP::Transport::HTTPX;

my $server = SOAP::Transport::HTTPX::Apache
   -> dispatch_to('/path/to/deployed/modules', 'Module::Name', 'Module::method'); 

sub handler { $server->handler(@_) }

1;

