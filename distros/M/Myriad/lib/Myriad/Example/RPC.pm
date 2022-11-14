package Myriad::Example::RPC;
our $VERSION = '1.001'; # VERSION
# To try this out, run:
#  myriad.pl service Myriad::Example::RPC rpc myriad.example.rpc
use Myriad::Service ':v1';
async method message : RPC {
 return 'Welcome to Myriad';
}
1;
