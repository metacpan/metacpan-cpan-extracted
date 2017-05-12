#!perl -w

use strict;
use Test::More tests => 51;

BEGIN { use_ok('Params::CallbackRequest') }

my $key = 'myCallbackTester';

sub mydie { die "Ouch!" }
sub myfault { die bless {}, 'TestException' }

my %cbs = ( pkg_key => $key,
            cb_key  => 'mydie',
            cb      => \&mydie
          );

my %fault_cb = ( pkg_key => $key,
                 cb_key  => 'myfault',
                 cb      => \&myfault );

##############################################################################
# Set up callback functions.
##############################################################################
# Check that we get a warning for when there are no callbacks.
{
    local $SIG{__WARN__} = sub {
        like( $_[0], qr/You didn't specify any callbacks/, "Check warning")
    };
    ok( Params::CallbackRequest->new, "Construct CBExec object without CBs" );
}

##############################################################################
# Try to construct a CBE object with a bad callback key.
my %c = %cbs;
$c{cb_key} = '';
eval {Params::CallbackRequest->new(callbacks => [\%c]) };
ok( my $err = $@, "Catch bad cb_key exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/Missing or invalid callback key/,
      "Check bad cb_key error message" );

##############################################################################
# Try to construct a CBE object with a bad priority.
%c = %cbs;
$c{priority} = 'foo';
eval {Params::CallbackRequest->new(callbacks => [\%c]) };
ok( $err = $@, "Catch bad priority exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/Not a valid priority: 'foo'/,
      "Check bad priority error message" );

##############################################################################
# Test a bad code ref.
my $msg = "Callback for package key 'myCallbackTester' and callback key " .
  "'coderef' not a code reference";
%c = %cbs;
$c{cb_key} = 'coderef';
$c{cb} = 'bogus'; # Ooops.
eval {Params::CallbackRequest->new(callbacks => [\%c]) };
ok( $err = $@, "Catch bad code ref exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/$msg/, "Check bad code ref error message" );

##############################################################################
# Test for a used key.
%c = my %b = %cbs;
$c{cb_key} = $b{cb_key} = 'bar'; # Ooops.
eval {Params::CallbackRequest->new(callbacks => [\%c, \%b]) };
ok( $err = $@, "Catch used key exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error,
      qr/Callback key 'bar' already used by package key '$key'/,
      "Check used key error message" );

##############################################################################
# Test a bad request code ref.
eval {Params::CallbackRequest->new(pre_callbacks => ['foo']) };
ok( $err = $@, "Catch bad request code ref exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error,
      qr/Request pre callback not a code reference/,
      'Check bad request code ref exception' );

##############################################################################
# Make sure that Params::Validate is using our exceptions.
$msg = 'The following parameter was passed in the call to ' .
  'Params::CallbackRequest::new but was not listed in the validation options: ' .
  'feh';
eval {Params::CallbackRequest->new(feh => 1) };
ok( $err = $@, "Catch bad parameter exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/$msg/, 'Check bad parameter exception' );

##############################################################################
# Construct one to be used for exceptions during the execution of callbacks.
##############################################################################
ok( my $cb_request = Params::CallbackRequest->new( callbacks => [\%cbs, \%fault_cb]),
    "Construct CBExec object" );
isa_ok($cb_request, 'Params::CallbackRequest' );

##############################################################################
# Send a bad argument to execute().
eval { $cb_request->request('foo') }; # oops!
ok( $err = $@, "Catch bad argument exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Params' );
like( $err->error, qr/Parameter 'foo' is not a hash reference/,
      'Check bad argument exception' );

##############################################################################
# Test the callbacks themselves.
##############################################################################
# Make sure an exception get thrown for a non-existant package.
my %params = ( 'NoSuchLuck|foo_cb' => 1 );
eval { $cb_request->request(\%params) };
ok( $err = $@, "Catch bad package exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::InvalidKey' );
like( $err->error, qr/No such callback package 'NoSuchLuck'/,
      "Check bad package message" );

##############################################################################
# Make sure an exception get thrown for a non-existant callback.
%params = ( "$key|foo_cb" => 1 );
eval { $cb_request->request(\%params) };
ok( $err = $@, "Catch missing callback exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::InvalidKey' );
like( $err->error, qr/No callback found for callback key '$key|foo_cb'/,
      "Check missing callback message" );

##############################################################################
# Now die from within our callback function.
%params = ( "$key|mydie_cb" => 1 );
eval { $cb_request->request(\%params) };
ok( $err = $@, "Catch our exception" );
isa_ok($err, 'Params::Callback::Exception' );
isa_ok($err, 'Params::Callback::Exception::Execution' );
like( $err->error, qr/^Error thrown by callback: Ouch! at/,
      "Check our mydie message" );
like( $err->callback_error, qr/^Ouch! at/, "Check our die message" );

##############################################################################
# Now throw our own exception.
%params = ( "$key|myfault_cb" => 1 );
eval { $cb_request->request(\%params) };
ok( $err = $@, "Catch our exception" );
isa_ok($err, 'TestException' );

##############################################################################
# Now test exception_handler.
%params = ( "$key|mydie_cb" => 1 );
ok( $cb_request = Params::CallbackRequest->new
    ( callbacks            => [\%cbs],
      exception_handler => sub {
          like( $_[0], qr/^Ouch! at/, "Custom check our die message" );
      }), "Construct CBExec object with custom exception handler" );
ok( $cb_request->request(\%params),
    "Execute callbacks with exception handler" );


1;
__END__
