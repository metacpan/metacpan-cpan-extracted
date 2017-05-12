#!perl -w

use strict;
use Test::More;
my $base_key = 'OOTester';
my $err_msg = "He's dead, Jim";

##############################################################################
# Figure out if the current configuration can handle OO callbacks.
BEGIN {
    plan skip_all => 'Object-oriented callbacks require Perl 5.6.0 or later'
      if $] < 5.006;

    plan skip_all => 'Attribute::Handlers and Class::ISA required for' .
      ' object-oriented callbacks'
      unless eval { require Attribute::Handlers }
      and eval { require Class::ISA };

    plan tests => 181;
}

##############################################################################
# Set up the callback class.
##############################################################################
package Params::Callback::TestObjects;

use strict;
use base 'Params::Callback';
__PACKAGE__->register_subclass( class_key => $base_key);
use Params::CallbackRequest::Exceptions abbr => [qw(throw_cb_exec)];

sub simple : Callback {
    my $self = shift;
    main::isa_ok($self, 'Params::Callback');
    main::isa_ok($self, __PACKAGE__);
    my $params = $self->params;
    $params->{result} = 'Simple Success';
}

sub complete : Callback(priority => 3) {
    my $self = shift;
    main::isa_ok($self, 'Params::Callback');
    main::isa_ok($self, __PACKAGE__);
    main::is($self->priority, 3, "Check priority is '3'" );
    my $params = $self->params;
    $params->{result} = 'Complete Success';
}

sub inherit : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = UNIVERSAL::isa($self, 'Params::Callback')
      ? 'Yes' : 'No';
}

sub highest : Callback(priority => 0) {
    my $self = shift;
    main::is( $self->priority, 0, "Check priority is '0'" );
}

sub upperit : PreCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = uc $params->{result} if $params->{do_upper};
}

sub pre_post : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{chk_post} = 1;
}

sub lowerit : PostCallback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = lc $params->{result} if $params->{do_lower};
}

sub class : Callback {
    my $self = shift;
    main::isa_ok( $self, __PACKAGE__);
    main::isa_ok( $self, $self->value);
}

sub chk_priority : Callback {
    my $self = shift;
    my $priority = $self->priority;
    my $val = $self->value;
    $val = 5 if $val eq 'def';
    main::is($priority, $val, "Check for priority '$val'" );
    my $params = $self->params;
    $params->{result} .= " " . $priority;
}

sub test_abort : Callback {
    my $self = shift;
    $self->abort(1);
}

sub test_aborted : Callback {
    my $self = shift;
    my $params = $self->params;
    my $val = $self->value;
    eval { $self->abort(1) } if $val;
    $params->{result} = $self->aborted($@) ? 'yes' : 'no';
}

sub exception : Callback {
    my $self = shift;
    if ($self->value) {
        # Throw an exception object.
        throw_cb_exec $err_msg;
    } else {
        # Just die.
        die $err_msg;
    }
}

sub same_object : Callback {
    my $self = shift;
    my $params = $self->params;
    if ($self->value) {
        main::is($self, $params->{obj}, "Check for same object" );
    } else {
        $params->{obj} = $self;
    }
}

1;

##############################################################################
# Now set up an emtpy callback subclass.
##############################################################################
package Params::Callback::TestObjects::Empty;
use strict;
use base 'Params::Callback::TestObjects';
__PACKAGE__->register_subclass( class_key => $base_key . 'Empty');
1;

##############################################################################
# Now set up an a subclass that overrides a parent method.
##############################################################################
package Params::Callback::TestObjects::Sub;
use strict;
use base 'Params::Callback::TestObjects';
__PACKAGE__->register_subclass( class_key => $base_key . 'Sub');

# Try a method with the same name as one in the parent, and which
# calls the super method.
sub inherit : Callback {
    my $self = shift;
    $self->SUPER::inherit;
    my $params = $self->params;
    $params->{result} .= ' and ';
    $params->{result} .= UNIVERSAL::isa($self, 'Params::Callback::TestObjects')
      ? 'Yes' : 'No';
}

# Try a totally new method.
sub subsimple : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = 'Subsimple Success';
}

# Try a totally new method.
sub simple : Callback {
    my $self = shift;
    my $params = $self->params;
    $params->{result} = 'Oversimple Success';
}

1;

##############################################################################
# Meanwhile, back at the ranch...
##############################################################################
package main;

# Keep track of who's who.
my %classes = ( $base_key           => 'Params::Callback::TestObjects',
                $base_key . 'Sub'   => 'Params::Callback::TestObjects::Sub',
                $base_key . 'Empty' => 'Params::Callback::TestObjects::Empty');

use_ok('Params::CallbackRequest');
my $all = 'ALL';
for my $key ($base_key, $base_key . "Empty", $all) {
    # Create the CBExec object.
    my $cb_request;
    if ($key eq 'ALL') {
        # Load all of the callback classes.
        ok( $cb_request = Params::CallbackRequest->new( cb_classes => $key ),
            "Construct $key CBExec object" );
        $key = $base_key;
    } else {
        # Load the base class and the subclass.
        ok( $cb_request = Params::CallbackRequest->new
            ( cb_classes => [$key, $base_key . 'Sub']),
            "Construct $key CBExec object" );
    }

    ##########################################################################
    # Now make sure that the simple callback executes.
    my %params = ("$key|simple_cb" => 1);
    ok( $cb_request->request(\%params), "Execute simple callback" );
    is( $params{result}, 'Simple Success', "Check simple result" );

    ##########################################################################
    # And the "complete" callback.
    %params = ("$key|complete_cb" => 1);
    ok( $cb_request->request(\%params), "Execute complete callback" );
    is( $params{result}, 'Complete Success', "Check complete result" );

    ##########################################################################
    # Check the class name.
    %params = ("$key|inherit_cb" => 1);
    ok( $cb_request->request(\%params), "Execute inherit callback" );
    is( $params{result}, 'Yes', "Check inherit result" );

    ##########################################################################
    # Check class inheritance and SUPER method calls.
    %params = ($base_key . "Sub|inherit_cb" => 1);
    ok( $cb_request->request(\%params), "Execute SUPER inherit callback" );
    is( $params{result}, 'Yes and Yes', "Check SUPER inherit result" );

    ##########################################################################
    # Try pre-execution callbacks.
    %params = (do_upper => 1,
               result   => 'upPer_mE');
    ok( $cb_request->request(\%params), "Execute pre callback" );
    is( $params{result}, 'UPPER_ME', "Check pre result" );

    ##########################################################################
    # Try post-execution callbacks.
    %params = ("$key|simple_cb" => 1,
               do_lower => 1);
    ok( $cb_request->request(\%params), "Execute post callback" );
    is( $params{result}, 'simple success', "Check post result" );

    ##########################################################################
    # Try a method defined only in a subclass.
    %params = ($base_key . "Sub|subsimple_cb" => 1);
    ok( $cb_request->request(\%params), "Execute subsimple callback" );
    is( $params{result}, 'Subsimple Success', "Check subsimple result" );

    ##########################################################################
    # Try a method that overrides its parent but doesn't call its parent.
    %params = ($base_key . "Sub|simple_cb" => 1);
    ok( $cb_request->request(\%params), "Execute oversimple callback" );
    is( $params{result}, 'Oversimple Success', "Check oversimple result" );

    ##########################################################################
    # Try a method that overrides its parent but doesn't call its parent.
    %params = ($base_key . "Sub|simple_cb" => 1);
    ok( $cb_request->request(\%params), "Execute oversimple callback" );
    is( $params{result}, 'Oversimple Success', "Check oversimple result" );

    ##########################################################################
    # Check that the proper class ojbect is constructed.
    %params = ("$key|class_cb" => $classes{$key});
    ok( $cb_request->request(\%params), "Execute class callback" );

    ##########################################################################
    # Check priority execution order for multiple callbacks.
    %params = ("$key|chk_priority_cb0"  => 0,
               "$key|chk_priority_cb2"  => 2,
               "$key|chk_priority_cb9"  => 9,
               "$key|chk_priority_cb7"  => 7,
               "$key|chk_priority_cb1"  => 1,
               "$key|chk_priority_cb4"  => 4,
               "$key|chk_priority_cb"   => 'def',
              );
    ok( $cb_request->request(\%params), "Execute priority order callback" );
    is($params{result}, " 0 1 2 4 5 7 9", "Check priority order result" );

    ##########################################################################
    # Emulate the sumission of an <input type="image" /> button.
    %params = ("$key|simple_cb.x" => 18,
               "$key|simple_cb.y" => 22 );
    ok( $cb_request->request(\%params), "Execute image  callback" );
    is( $params{result}, 'Simple Success', "Check single simple result" );

    ##########################################################################
    # Make sure that if we abort, no more callbacks execute.
    %params = ("$key|test_abort_cb0" => 1,
               "$key|simple_cb" => 1,
                result => 'still here' );
    is( $cb_request->request(\%params), 1, "Execute abort callback" );
    is( $params{result}, 'still here', "Check abort result" );

    ##########################################################################
    # Test aborted for a false value.
    %params = ("$key|test_aborted_cb" => 0 );
    is( $cb_request->request(\%params), $cb_request,
        "Execute false aborted callback" );
    is( $params{result}, 'no', "Check false aborted result" );

    ##########################################################################
    # Test aborted for a true value.
    %params = ("$key|test_aborted_cb" => 1 );
    ok( $cb_request->request(\%params), "Execute true aborted callback" );
    is( $params{result}, 'yes', "Check true aborted result" );

    ##########################################################################
    # Try throwing an execption.
    %params = ("$key|exception_cb" => 1 );
    eval { $cb_request->request(\%params) };
    ok( my $err = $@, "Catch $key exception" );
    isa_ok($err, 'Params::Callback::Exception');
    isa_ok($err, 'Params::Callback::Exception::Execution');
    is( $err->error, $err_msg, "Check error message" );

    ##########################################################################
    # Try die'ing.
    %params = ("$key|exception_cb" => 0 );
    eval { $cb_request->request(\%params) };
    ok( $err = $@, "Catch $key die" );
    isa_ok($err, 'Params::Callback::Exception');
    isa_ok($err, 'Params::Callback::Exception::Execution');
    like( $err->error, qr/^Error thrown by callback: $err_msg/,
        "Check die error message" );

    ##########################################################################
    # Make sure that the same object is called for multiple callbacks in the
    # same class.
    %params = ("$key|same_object_cb1" => 0,
               "$key|same_object_cb" => 1);
    ok( $cb_request->request(\%params), "Execute same object callback" );

    ##########################################################################
    # Check priority 0 sticks.
    %params = ("$key|highest_cb" => undef);
    ok( $cb_request->request(\%params), "Execute check priority 0 attribute" );
}

__END__
