#!/usr/bin/perl -w

HelloWorld->create_server( 'Hello' );

package HelloWorld;

use strict;
use warnings;

use POE::XUL::Node;

use base 'POE::XUL::Application';

sub boot
{
    Boot( "Hello world" );
    Window( Description( 'Hello world' ) );
}
