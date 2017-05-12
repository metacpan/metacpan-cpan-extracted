#!perl -w

use strict;
use Test::More tests => 15;

BEGIN { use_ok('Params::CallbackRequest') }

my $key = 'myCallbackTester';
my $cbs = [];

##############################################################################
# Set up callback functions.
##############################################################################
# Callback to test the value of the package key attribute.
sub test_pkg_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->pkg_key;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_pkg_key',
              cb      => \&test_pkg_key
            },
            { pkg_key => $key . '_more',
              cb_key  => 'test_pkg_key',
              cb      => \&test_pkg_key
            };

##############################################################################
# Callback to test the value returned by the class_key method.
sub test_class_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->class_key;
}
push @$cbs, { pkg_key => $key,
              cb_key  => 'test_class_key',
              cb      => \&test_class_key
            },
            { pkg_key => $key. '_more',
              cb_key  => 'test_class_key',
              cb      => \&test_class_key
            };

##############################################################################
# Callback to test the value of the trigger key attribute.
sub test_trigger_key {
    my $cb = shift;
    my $params = $cb->params;
    $params->{result} .= $cb->trigger_key;
}

push @$cbs, { pkg_key => $key,
              cb_key  => 'test_trigger_key',
              cb      => \&test_trigger_key
            },
            { pkg_key => $key . '_more',
              cb_key  => 'test_trigger_key',
              cb      => \&test_trigger_key
            };

##############################################################################
# Construct the CallbackRequest object.
##############################################################################

ok( my $cb_request = Params::CallbackRequest->new( callbacks => $cbs),
    "Construct CBExec object" );
isa_ok($cb_request, 'Params::CallbackRequest' );

##############################################################################
# Test the callbacks themselves.
##############################################################################
# Test the package key.
my %params = ( "$key|test_pkg_key_cb" => 1 );
ok( $cb_request->request(\%params), "Execute test_pkg_key callback" );
is( $params{result}, $key, "Check pkg key" );

# And multiple package keys.
%params = ( "$key|test_pkg_key_cb1" => 1,
            "$key\_more|test_pkg_key_cb2" => 1,
            "$key|test_pkg_key_cb3" => 1,
          );
ok( $cb_request->request(\%params), "Execute test_pkg_key callback again" );
is( $params{result}, "$key$key\_more$key", "Check pkg key again" );

##############################################################################
# Test the class key.
%params = ( "$key|test_class_key_cb" => 1 );
ok( $cb_request->request(\%params), "Execute test_class_key callback" );
is( $params{result}, $key, "Check class key" );

# And multiple class keys.
%params = ( "$key|test_class_key_cb1" => 1,
            "$key\_more|test_class_key_cb2" => 1,
            "$key|test_class_key_cb3" => 1,
          );
ok( $cb_request->request(\%params), "Execute test_class_key callback again" );
is( $params{result}, "$key$key\_more$key", "Check class key again" );

##############################################################################
# Test the trigger key.
%params = ( "$key|test_trigger_key_cb" => 1 );
ok( $cb_request->request(\%params), "Execute test_trigger_key callback" );
is( $params{result}, "$key|test_trigger_key_cb", "Check trigger key" );

# And multiple trigger keys.
%params = ( "$key|test_trigger_key_cb1" => 1,
            "$key\_more|test_trigger_key_cb2" => 1,
            "$key|test_trigger_key_cb3" => 1,);

ok( $cb_request->request(\%params), "Execute test_trigger_key callbac again" );
is( $params{result}, "$key|test_trigger_key_cb1$key\_more|" .
    "test_trigger_key_cb2$key|test_trigger_key_cb3",
    "Check trigger key again" );

1;
__END__
