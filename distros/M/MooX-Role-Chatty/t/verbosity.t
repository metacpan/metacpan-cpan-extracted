#!/usr/bin/env perl

use Test::More;

plan skip_all => 'Log::Any::Adapter::Carp not installed'
  unless eval { require Log::Any::Adapter::Carp };

package My::Test;

use Moo;
with 'MooX::Role::Chatty';
my $Message;
$SIG{__WARN__} = sub { $Message = shift; };

package main;

my $c = My::Test->new;

$c->logger->info('Not logged');
ok( !defined $Message, "Don't log when verbosity == 0" );

undef $Message;
$c->logger->emergency('Logged');
like( $Message, qr/\d{4}-.+:: Logged/, 'Except in emergency' );

$c->verbose(1);
$c->logger->notice('Logged');
like( $Message, qr/\d{4}-.+:: Logged/, 'Log info when verbosity higher' );

$c->verbose(-1);
undef $Message;
$c->logger->notice("Not logged\n");
ok( !defined $Message, "Changing verbosity alters logging . . ." );

undef $Message;
$c->logger->warn('Logged');
like(
    $Message,
    qr/\d{4}-.+:: Logged/,
    '. . . but still occurs at appropriate level'
);

done_testing;
