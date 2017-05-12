#!perl -w

use strict;
use Test::More;
my $base_key = 'OOTester';

##############################################################################
# Figure out if the current configuration can handle OO callbacks.
BEGIN {
    plan skip_all => 'Object-oriented callbacks require Perl 5.6.0 or later'
      if $] < 5.006;

    plan skip_all => 'Attribute::Handlers and Class::ISA required for' .
      ' object-oriented callbacks'
      unless eval { require Attribute::Handlers }
      and eval { require Class::ISA };

    plan tests => 20;
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

sub lowerit : PostCallback {
    my $self = shift;
    my $params = $self->params;
    if ($params->{do_lower}) {
        main::isa_ok($self, 'Params::Callback');
        main::isa_ok($self, __PACKAGE__);
        $params->{result} = lc $params->{result};
    }
}

1;
##############################################################################
# Set up another callback class to test the default class key.
package Params::Callback::TestKey;
use strict;
use base 'Params::Callback';
__PACKAGE__->register_subclass;

sub my_key : Callback {
    my $self = shift;
    main::is($self->pkg_key, __PACKAGE__, "Check package key" );
    main::is($self->class_key, __PACKAGE__, "Check class key" );
}

##############################################################################
# Back in the real world...
##############################################################################
package main;
use strict;
use_ok('Params::CallbackRequest');

##############################################################################
# Set up a functional callback we can use.
sub another {
    my $cb = shift;
    main::isa_ok($cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result} = 'Another Success';
}

##############################################################################
# And a functional request callback.
sub presto {
    my $cb = shift;
    main::isa_ok($cb, 'Params::Callback');
    my $params = $cb->params;
    $params->{result} = 'PRESTO' if $params->{do_presto};
}

##############################################################################
# Construct the combined callback exec object.
ok( my $cb_request = Params::CallbackRequest->new
    ( callbacks => [{ pkg_key => 'foo',
                      cb_key => 'another',
                      cb => \&another}],
      cb_classes => 'ALL',
      pre_callbacks => [\&presto] ),
    "Construct combined CBExec object" );

##############################################################################
# Make sure the functional callback works.
my %params = ( 'foo|another_cb' => 1);
ok( $cb_request->request(\%params), "Execute functional callback" );
is( $params{result}, 'Another Success', "Check functional result" );

##############################################################################
# Make sure OO callback works.
%params = ( "$base_key|simple_cb" => 1);
ok( $cb_request->request(\%params), "Execute OO callback" );
is( $params{result}, 'Simple Success', "Check OO result" );

##############################################################################
# Make sure that functional and OO request callbacks execute, too.
%params = ( do_lower => 1,
            do_presto => 1);
ok( $cb_request->request(\%params), "Execute request callbacks" );
is( $params{result}, 'presto', "Check request result" );

##############################################################################
# Make sure that the default class key is the class name.
%params = ( "Params::Callback::TestKey|my_key_cb" => 1);
ok( $cb_request->request(\%params), "Execute class key callback" );


1;
__END__
