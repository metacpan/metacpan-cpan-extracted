#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use_ok( 'Net::IChat' );
ok( my $me = Net::IChat->me() );
ok( $me->announce() );

ok( my $other = Net::IChat->me() );
ok( $other->port( 5302 ) );
ok( $other->first( 'Another' ) );
ok( $other->last( 'Client' ) );
ok( $other->name('Foo@Twitter') );
ok( $other->announce() );

ok( my $clients = Net::IChat->clients() );
ok( @$clients > 0, "we should at least be available" );


## we have to do this, as Module::Build seems to not like forking
## processes in tests.
kill( 9, $me->pid );
kill( 9, $other->pid );
