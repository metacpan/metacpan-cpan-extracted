use warnings;
use strict;

##############################################################################
package Wifty::UI::mixed_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'mixed' => sub {
    my $self = shift;
    div { outs_raw "Invocant:  '$self'" };
    div { 'Variable ', $self->package_variable('VARIABLE') };
};

private template shhhh => sub { };

##############################################################################
package Wifty::UI::mixed_subclass_pkg;
use base qw/Wifty::UI::mixed_pkg/;
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

mix Wifty::UI::mixed_pkg under '/mixed_pkg', setting { VARIABLE => 'SET' } ;
mix Wifty::UI::mixed_pkg under '/mixed_pkg2';
mix Wifty::UI::mixed_subclass_pkg under '/mixed_subclass_pkg';

##############################################################################
package main;
use Template::Declare::Tags;

# Mix from outside the class.
mix Wifty::UI::mixed_pkg into Wifty::UI, under '/mixed_pkg3';
# And reverse.
mix Wifty::UI::mixed_pkg under '/mixed_pkg4', into Wifty::UI

# Fire it up.
Template::Declare->init( dispatch_to => ['Wifty::UI'] );

use Test::More tests => 30;
require "t/utils.pl";

ok( Wifty::UI::mixed_pkg->has_template('mixed'), 'Mixed package should have template' );
ok( !  Wifty::UI->has_template('mixed'), 'Unrelated package should not' );
ok( Wifty::UI::mixed_subclass_pkg->has_template('mixed'), 'Subclass should' );

ok( Template::Declare->has_template('mixed_pkg/mixed'), 'TD should find mix' );
ok( Template::Declare->has_template('mixed_pkg2/shhhh', 1), 'TD should find private mix' );

ok( Template::Declare->has_template('mixed_subclass_pkg/mixed'),
    'Mix should be visible in a subclass, too' );

{
    # Try the first mix with a variable set.
    ok my $simple = ( show('mixed_pkg/mixed') ), 'Should get output from mix template';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    like( $simple, qr'Variable SET' , "The variable was set");
    like( $simple, qr{'Wifty::UI'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the second mix with no variable.
    ok my $simple = ( show('mixed_pkg2/mixed') ), 'Should get output from second mix';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the third mix using `into`.
    ok my $simple = ( show('mixed_pkg3/mixed') ), 'Should get output from third mix';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    # Try the fourth with `into` and `under` reversed.
    ok my $simple = ( show('mixed_pkg4/mixed') ), 'Should get output from fourth mix';
    like( $simple, qr'Invocant:', 'Its output should be right' );
    unlike( $simple, qr'Varialble SET' , 'But the variable should not be set');
    like( $simple, qr{'Wifty::UI'},
        '$self is correct in template block' );
    ok_lint($simple);
}

{
    ok my $simple = ( show('mixed_subclass_pkg/mixed') ),
        'Should get output from superclass template';
    like(
        $simple,
        qr'Invocant:',
        "We should get the mixed version in the subclass"
    );
    like(
        $simple,
        qr{'Wifty::UI'},
        '$self is correct in template block'
    );
    ok_lint($simple);
}

1;
