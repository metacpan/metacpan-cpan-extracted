package Myriad::Example::Startup;
our $VERSION = '1.001'; # VERSION
# To try this out, run:
#  myriad.pl service Myriad::Example::Startup
use Myriad::Service ':v1';
async method startup (%args) {
 $log->infof('This is our example service, running code in the startup method');
}
1;
