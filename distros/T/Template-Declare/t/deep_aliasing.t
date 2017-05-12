use warnings;
use strict;

##############################################################################
package SearchPlugin::View;

use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'search' => sub {
    h1 {'SearchPlugin::View::search'};
};

##############################################################################
package ListPlugin::View;

use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'listing' => sub {
    h1 {'ListPlugin::View::listing'};
};

alias SearchPlugin::View under '/';

##############################################################################
package MyApp::View;

use base qw/Template::Declare/;
use Template::Declare::Tags;

template 'toplevel' => sub {h1{'Toplevel'}};

alias ListPlugin::View under '/plugin';

##############################################################################
package main;
Template::Declare->init( dispatch_to => ['MyApp::View'] );

use Test::More tests => 14;
use Test::Warn;
require "t/utils.pl";

ok( MyApp::View->has_template('toplevel'), 'Should have toplevel template' );
ok( !MyApp::View->has_template('listing'), "the listing template isn't imported to the top level");
ok( !MyApp::View->has_template('search'), "The search template isn't imported to the top level" );
ok( MyApp::View->has_template('/plugin/listing'), 'has listing template' );
ok( MyApp::View->has_template('/plugin/search'), 'has search template' );

{
    my $simple = ( Template::Declare->show('toplevel'));
    like( $simple, qr'Toplevel', 'Can execute toplevel template' );
}
{
    warning_like {
        my $simple = ( Template::Declare->show('listing') ||'');
        unlike( $simple, qr'listing',
            'Cannot call a toplevel "listing" template' );
        }
        qr/The template 'listing' could not be found/,
        "listing is private"

}
warning_like {
    my $simple = ( Template::Declare->show('search')||'');
    unlike( $simple, qr'search', "Cannot call a toplevel /search" );
} qr/The template 'search' could not be found/, "Search could not be found";

{

    my $simple = ( Template::Declare->show('/plugin/listing'));
    like( $simple, qr'listing', "Can call /plugin/listing" );
    $simple = ( Template::Declare->show('plugin/listing'));
    like( $simple, qr'listing', "Can call plugin/listing" );
}
{
    my $simple = ( Template::Declare->show('/plugin/search'));
    like( $simple, qr'search' , "Can call /plugin/search");
    $simple = ( Template::Declare->show('plugin/search'));
    like( $simple, qr'search' , "Can call plugin/search");
}

1;
