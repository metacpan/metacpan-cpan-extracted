use strict;
use warnings;

use Test::More tests => 4;

use Plient;

ok( Plient->plient_support('File','GET'), 'supports File GET' );
# ok( Plient->available('HTTP','GET'), 'supports HTTP GET' );


{
    # Fake1 doesn't look like a Plient Handler
    package Plient::Handler::Fake1;
    Plient->_add_handlers('Plient::Handler::Fake1');
}

ok( ! grep( { /Fake1/ } Plient->all_handlers ), 'not found Fake1 handler' );

{
    # make Fake2 looks like a Plient Handler
    package Plient::Handler::Fake2;
    sub support_protocol {};
    sub support_method {};
    Plient->_add_handlers('Plient::Handler::Fake2');
}

ok( grep( { /Fake2/ } Plient->all_handlers ), 'found Fake2 handler' );

{

    # Fake3 is based on 'Plient::Handler'
    package Plient::Handler::Fake3;
    use base 'Plient::Handler';
    __PACKAGE__->_add_to_plient();
}

ok( grep( { /Fake3/ } Plient->all_handlers ), 'found Fake3 handler' );

