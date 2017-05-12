use warnings;
use strict;

##############################################################################
package Wifty::UI::aliased_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'aliased' => sub {
    my $self = shift;
    div { outs_raw "Invocant:  '$self'" };
    div { 'Variable ', $self->package_variable('VARIABLE') };
};

private template shhhh => sub { };

##############################################################################
package Wifty::UI::aliased_subclass_pkg;
use base qw/Wifty::UI::aliased_pkg/;
use Template::Declare::Tags;

##############################################################################
package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {

    html {
        head {};
        body { show 'private-content'; };
    }

};

private template 'private-content' => sub {
    my $self = shift;
    with( id => 'body' ), div {
        outs( 'This is my content from' . $self );
    };
};

alias Wifty::UI::aliased_pkg under '/aliased_pkg', setting { VARIABLE => 'SET' } ;
alias Wifty::UI::aliased_pkg under '/aliased_pkg2';
alias Wifty::UI::aliased_subclass_pkg under '/aliased_subclass_pkg';

##############################################################################
package main;
use Template::Declare::Tags;

# Alias from outside the class.
alias Wifty::UI::aliased_pkg into Wifty::UI, under '/aliased_pkg3';
# And reverse.
alias Wifty::UI::aliased_pkg under '/aliased_pkg4', into Wifty::UI

# Fire it up.
Template::Declare->init( dispatch_to => ['Wifty::UI'] );

use Test::More tests => 30;
require "t/utils.pl";

ok( Wifty::UI::aliased_pkg->has_template('aliased'), 'Aliased package should have template' );
ok( !  Wifty::UI->has_template('aliased'), 'Unrelated package should not' );
ok( Wifty::UI::aliased_subclass_pkg->has_template('aliased'), 'Subclass should' );

ok( Template::Declare->has_template('aliased_pkg/aliased'), 'TD should find alias' );
ok( Template::Declare->has_template('aliased_pkg2/shhhh', 1), 'TD should find private mix' );

ok( Template::Declare->has_template('aliased_subclass_pkg/aliased'),
    'Alias should be visible in a subclass, too' );

{
    # Try the first alias with a variable set.
    ok my $simple = ( show('aliased_pkg/aliased') ), 'Should get output from alias template';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    like( $simple, qr'Variable SET' , "The variable was set");
    like( $simple, qr{'Wifty::UI::aliased_pkg'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the second alias with no variable.
    ok my $simple = ( show('aliased_pkg2/aliased') ), 'Should get output from second alias';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI::aliased_pkg'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the third alias using `into`.
    ok my $simple = ( show('aliased_pkg3/aliased') ), 'Should get output from third alias';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI::aliased_pkg'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the fourth with `into` and `under` reversed.
    ok my $simple = ( show('aliased_pkg4/aliased') ), 'Should get output from fourth alias';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI::aliased_pkg'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    ok my $simple = ( show('aliased_subclass_pkg/aliased') ),
        'Should get output from superclass template';
    like(
        $simple,
        qr'Invocant:',
        "We should get the aliased version in the subclass"
    );
    like(
        $simple,
        qr{'Wifty::UI::aliased_subclass_pkg'},
        '$self is correct in template block'
    );
    ok_lint($simple);
}

1;
