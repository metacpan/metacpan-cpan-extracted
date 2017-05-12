#!perl

package FakeSVC;
use strict;
use warnings;
use Test::More;

sub new { return bless {}, shift }
sub register_hook {
    my ( $self, $plugin, $hook, $callback ) = @_;

    is( $plugin,       'ExpandSSL',           'correct plugin name' );
    is( $hook,         'start_proxy_request', 'correct hook'        );
    is( ref $callback, 'CODE',                'callback is coderef' );

    $callback->('me!');
}

package main;
use strict;
use warnings;

use Test::More tests => 11;
use Perlbal::Plugin::ExpandSSL;

{
    no warnings 'redefine';
    *Perlbal::Plugin::ExpandSSL::build_registry = sub {
        ok( 1, 'build_registry was called' );
    };

    *Perlbal::Plugin::ExpandSSL::expand_ssl = sub {
        ok( 1, 'expand_ssl was called' );
        cmp_ok( scalar @_, '==', 1, 'called by us' );
        is( $_[0], 'me!', 'definitely called by us' );
    };
}

ok( Perlbal::Plugin::ExpandSSL::load(),       'load returns true'       );
ok( Perlbal::Plugin::ExpandSSL::unload(),     'unload returns true'     );
ok( Perlbal::Plugin::ExpandSSL::unregister(), 'unregister returns true' );

my $svc = FakeSVC->new;
isa_ok( $svc, 'FakeSVC' );
Perlbal::Plugin::ExpandSSL->register($svc);

