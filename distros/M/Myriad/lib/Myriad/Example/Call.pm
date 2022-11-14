package Myriad::Example::Call;
our $VERSION = '1.001'; # VERSION
# To try this out, run:
#  myriad.pl service Myriad::Example::Call rpc myriad.example.call/remote_call
use Myriad::Service ':v1';
async method remote_call : RPC (%args) {
 my $srv = await $api->service_by_name('myriad.example.call');
 return await $srv->target_method;
}
async method target_method : RPC {
 return 'This is a method we call from within another service';
}
1;
