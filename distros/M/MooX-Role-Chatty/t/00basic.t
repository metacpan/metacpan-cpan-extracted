#!/usr/bin/env perl

use Test::More;

require_ok('MooX::Role::Chatty');

package My::Test::Logger;
use Moo 2;

sub info { 1; }
sub warn { 1; }

package My::Test::Logger::Not;
use Moo;

sub info { 1; }

package My::Test;

use Moo;
with 'MooX::Role::Chatty';

package main;

my $l1     = My::Test::Logger->new;
my $l2     = My::Test::Logger->new;
my $natter = My::Test->new( verbose => 1, logger => $l1 );

is( $natter->verbose, 1, 'Get verbosity' );
ok( $natter->verbose(2), 'Set verbosity' );
is( $natter->verbose, 2, 'Verbosity changed' );

isa_ok( $natter->logger,     'My::Test::Logger', 'Get logger (logger)' );
isa_ok( $natter->get_logger, 'My::Test::Logger', 'Get logger (get_logger)' );

# clear_logger tested in logger.t
ok( $natter->logger($l2), 'Set logger' );
is( $natter->logger, $l2, 'Logger changed' );
ok( !eval { $natter->logger( My::Test::Logger::Not->new ) },
    'Logger failed constraint' );

ok( $natter->can('remark'), 'Can remark' );

done_testing;
