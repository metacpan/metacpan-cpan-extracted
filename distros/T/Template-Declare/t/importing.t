use warnings;
use strict;

##############################################################################
package Wifty::UI::imported_pkg;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'imported' => sub {
    my $self = shift;
    div { outs_raw "Invocant: '$self'" };
};

##############################################################################
package Wifty::UI::imported_subclass_pkg;
use base qw/Wifty::UI::imported_pkg/;
use Template::Declare::Tags;

##############################################################################
package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;

template simple => sub {
    print '# ', ref +shift, $/;
    html {
        head {};
        body { show 'private-content'; };
    }

};

private template 'private-content' => sub {
    my $self = shift;
    with ( id => 'body' ), div {
        outs( 'This is my content from' . $self );
    };
};

import_templates Wifty::UI::imported_pkg under '/imported_pkg';
import_templates Wifty::UI::imported_subclass_pkg under '/imported_subclass_pkg';

##############################################################################
package Wifty::OtherUI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
import_templates Wifty::UI::imported_pkg under '/other_pkg';
import_templates Wifty::UI::imported_subclass_pkg under '/other_subclass';

##############################################################################
package main;
use Template::Declare::Tags;
Template::Declare->init( dispatch_to => ['Wifty::UI'] );

use Test::More tests => 18;
#use Test::More 'no_plan';
require "t/utils.pl";

# Visibility.
ok( Wifty::UI::imported_pkg->has_template('imported'),
    'Original template should be visible in its own class' );
ok( Wifty::UI::imported_subclass_pkg->has_template('imported'),
    'And be visible in a subclass');
ok( !Template::Declare->has_template('imported'),
    'But it should not be visible in Template::Declare');
ok( !Wifty::UI->has_template('imported'),
    'Nor in the packge it was imported into' );

ok( Template::Declare->has_template('imported_pkg/imported'),
    'But it should be visible in its imported path' );
ok( Template::Declare->has_template('imported_subclass_pkg/imported'),
    'And it should be visible when imported from a subclass' );

ok( !Template::Declare->has_template('other_pkg/imported'),
    'The imported template should not be visible when imported into non-root package' );

# Translate the path to where it was imported.
TODO: {
    local $TODO = 'path_for is confused', 1;
    is(
        Wifty::UI::imported_subclass_pkg->path_for('imported'),
        '/imported_subclass_pkg/imported',
        'The path for the imported template should be correct'
    );
}
is(
    Wifty::UI::imported_subclass_pkg->path_for('imported'),
    '/other_subclass/imported',
    'The imported template path should be correct for the last package it was imported into'
);
is( Wifty::UI->path_for('simple'), '/simple', 'Simple template should be in the root path' );

{
    ok my $simple = ( show('imported_pkg/imported') ), 'Should get output for imported template';
    like( $simple, qr'Invocant:', 'Its output should be correct' );
    like( $simple, qr{'Wifty::UI'}, '$self is correct in template block' );
    ok_lint($simple);
}
{
    ok my $simple = ( show('imported_subclass_pkg/imported') ),
        'Should get output from imported template from subclass';
    like(
        $simple,
        qr'Invocant:',
        "We got the imported version in the subclass"
    );
    like(
        $simple,
        qr{'Wifty::UI'},
        '$self is correct in template block'
    );
    ok_lint($simple);
}
1;
