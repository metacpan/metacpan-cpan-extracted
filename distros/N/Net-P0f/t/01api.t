#!/usr/bin/perl -T
use strict;
use Test::More;
BEGIN { plan tests => 48 }

my $p0f;

# check the functions defined in Net::P0f
use Net::P0f;
ok( exists &Net::P0f::new                  , "Net::P0f::new" );
ok( exists &Net::P0f::AUTOLOAD             , "Net::P0f::AUTOLOAD" );
ok( exists &Net::P0f::DESTROY              , "Net::P0f::DESTROY" );
ok( exists &Net::P0f::loop                 , "Net::P0f::loop" );
ok( exists &Net::P0f::lookupdev            , "Net::P0f::lookupdev" );
ok( exists &Net::P0f::findalldevs          , "Net::P0f::findalldevs" );

# check the functions defined in Net::P0f::Backend::CmdFE
use Net::P0f::Backend::CmdFE;
ok( exists &Net::P0f::Backend::CmdFE::init , "Net::P0f::Backend::CmdFE::init" );
ok( exists &Net::P0f::Backend::CmdFE::run  , "Net::P0f::Backend::CmdFE::run" );

# check the functions defined in Net::P0f::Backend::Socket
use Net::P0f::Backend::Socket;
ok( exists &Net::P0f::Backend::Socket::init, "Net::P0f::Backend::Socket::init" );
ok( exists &Net::P0f::Backend::Socket::run , "Net::P0f::Backend::Socket::run"  );

# check the functions defined in Net::P0f::Backend::XS
use Net::P0f::Backend::XS;
ok( exists &Net::P0f::Backend::XS::init    , "Net::P0f::Backend::XS::init" );
ok( exists &Net::P0f::Backend::XS::run     , "Net::P0f::Backend::XS::run" );

# create an object and check that the previous functions 
# are available as object methods
my %backends = (
    ''       => 'Net::P0f::Backend::CmdFE', 
    'cmd'    => 'Net::P0f::Backend::CmdFE', 
    'socket' => 'Net::P0f::Backend::Socket', 
    'xs'     => 'Net::P0f::Backend::XS', 
);

for my $backend ('', 'cmd', 'socket', 'xs') {
    $p0f = new Net::P0f backend => $backend;
    ok( defined $p0f                   , "object created using '$backend' backend" );
    is( ref $p0f, $backends{$backend}  , " > object is a blessed ref" );
    ok( $p0f->isa($backends{$backend}) , " > object ISA $backends{$backend}" );

    for my $method (qw(new loop lookupdev findalldevs init run)) {
        ok( defined $p0f->can('new')   , " - object can $method()" );
    }

    $p0f = undef;
}

