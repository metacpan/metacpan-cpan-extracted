#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;
use Test::Warn;

use Module::PluginFinder;

my $f;

warning_is( sub { $f = Module::PluginFinder->new(
                          search_path => 't::lib',
                          typefunc    => 'size',
                       ); },
            undef,
            'size factory throws no warning' );

is( $f->find_module( "small" ), 't::lib::Yellow', '$f->find_module( "small" )' );

is( $f->find_module( "huge" ), undef, '$f->find_module( "huge" )' );

my $colour = $f->construct( "medium", 10 );

ok( defined $colour, 'defined $colour' );
isa_ok( $colour, "t::lib::Red", '$colour isa t::lib::Red' );

is_deeply( $colour, [ 10 ], 'forwarded constructor args for $colour' );

# Can't predict the exact order when testing so have to use some regexps
warnings_like( sub { $f = Module::PluginFinder->new(
                             search_path => 't::lib',
                             typefunc    => 'kind',
                          ); },
            [ { carped => qr/^Already found module 't::lib::\w+' for type 'colour'; not adding 't::lib::\w+' as well/ },
              { carped => qr/^Already found module 't::lib::\w+' for type 'colour'; not adding 't::lib::\w+' as well/ },
              { carped => qr/^Already found module 't::lib::\w+' for type 'colour'; not adding 't::lib::\w+' as well/ }
            ],
            'kind factory throws warnings' );
