#!/usr/bin/perl

# We're checking that application_dir returns sensibly.

use strict;
use warnings;

use RTF::Control;

use RTF::TEXT::Converter;

use Test::More tests => 1;

{

    my $object = RTF::Control->new( -confdir => 'asdfasdf' );
    is( $object->application_dir, 'asdfasdf',
        '-confdir to set application_dir works' );

}
