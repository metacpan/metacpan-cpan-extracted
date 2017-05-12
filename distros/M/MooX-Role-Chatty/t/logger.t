#!/usr/bin/env perl

use Test::More;

package My::Test::Logger;
use Moo;
my $Message;
sub info { $Message = $_[1]; }
sub warn { $Message = $_[1]; }

package My::Test;
use Moo;
with 'MooX::Role::Chatty';

package main;

my $Warned;
$SIG{__WARN__} = sub { $Warned = shift; };

my $c = My::Test->new( verbose => 2, logger => My::Test::Logger->new );

$c->logger->info('Logged');
is( $Message, 'Logged', 'Log info via assigned logger' );
ok( !defined $Warned, '. . . and not via default' );

SKIP: {
    skip 'Log::Any::Adapter::Carp not installed', 2
      unless eval { require Log::Any::Adapter::Carp };

    $c->clear_logger;
    undef $Warned;
    undef $Message;
    $c->logger->info('Logged');
    ok( !defined $Message, 'Logger cleared' );
    like(
        $Warned,
        qr/\d{4}-\w{3}-\d{2} \d{2}:\d{2}:\d{2} :: Logged/,
        '. . . and default picks up'
    );
}

$c->logger( My::Test::Logger->new );
undef $Warned;
undef $Message;
$c->logger->info("Logged\n");
is( $Message, "Logged\n", 'Set new logger' );
ok( !defined $Warned, '. . . and default stops logging' );

done_testing;
