use strict;
use warnings;

use Test::More;
use Test::MockModule;

use Net::FreeIPA;

my $mockbase = Test::MockModule->new("Net::FreeIPA::Base");
my $mockrpc = Test::MockModule->new("Net::FreeIPA::RPC");

my $rpc_args = {};

my $error;
$mockbase->mock('error', sub {shift; $error = \@_; diag "error: @_"});


my $f = Net::FreeIPA->new();
isa_ok($f, 'Net::FreeIPA::API', "Net::FreeIPA instance is a Net::FreeIPA::API too");


=head2 test api_ AUTOLOAD / $api_method

=cut

$mockrpc->mock('rpc', sub {

    my ($self, $request) = @_;

    isa_ok($request, 'Net::FreeIPA::Request', 'isa Request instance');
    return undef if (! $request);

    $rpc_args = {
        command => $request->{command},
        args => $request->{args},
        opts => $request->{opts},
        rpc_opts => $request->{rpc},
    };

    return 123; # something unique
});


sub tapi
{
    my ($res, $msg, $exp, $rpc) = @_;

    if($rpc) {
        is($res, $exp, "return value $msg");
        ok(! defined($error), "no error $msg");
        is_deeply($rpc_args, $rpc, "rpc called $msg");
    } else {
        # an error
        ok(! defined($res), "undef returned on error $msg");
        # Do not test the error message anymore; it's handled by RPC now
        #like($error->[0], qr{$exp}, "error message $msg");
        ok(! $rpc_args->{command}, "rpc command empty, rpc not called $msg");
    }
    # Reset, ok for next time
    $error = undef;
    $rpc_args = {};
}

# Reset once, they are re-reset at end of tapi
$error = undef;
$rpc_args = {};

tapi($f->api_user_add() || undef,
     "user_add api called without argument",
     "api_user_add: 1-th argument name uid mandatory with undefined value");
tapi($f->api_user_add("myuser", gecosss => 'mygecos') || undef,
     "user_add api called without missing mandatory option givenname",
     "api_user_add: option name givenname mandatory with undefined value");
tapi($f->api_user_add("myuser", gecosss => 'mygecos', givenname => 'myname', sn => 'last') || undef,
     "user_add api called with invalid option",
     "api_user_add: option invalid name gecosss");
tapi($f->api_user_add("myuser", gecos => 'mygecos', givenname => 'myname', sn => 'last', __result_path => 'some/path') || undef,
     "user_add api correctly called", 123, {
         command => 'user_add',
         args => ['myuser'],
         opts => {gecos => 'mygecos', givenname => 'myname', sn => 'last'},
         rpc_opts => {result_path => 'some/path'}, # __ removed and passed to rpc as option
     });



done_testing;
