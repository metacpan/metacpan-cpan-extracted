#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;

use Test::More tests => 5;

BEGIN { use_ok('MojoX::Logite') };

my $testlog = Cwd::cwd . '/testlog.db';

my $logite = MojoX::Logite->new(
  'path' => $testlog,
  'prune' => 1,
  'package' => 'Foo::Bar::Log',
  #'user_version' => 1,
  #'cache' => '/tmp/cache-orlite/'
);

is ( $logite->package =~ m/Foo::Bar::Log/, 1, "package match");

is ( $logite->package_table eq 'Foo::Bar::Log::Logitetable', 1, "package table match");

$logite->debug("Why isn't this working?");
$logite->info("FYI: it happened again");
$logite->warn("This might be a problem");
$logite->error("Garden variety error");
$logite->fatal("Boom!");

is ( $logite->package_table->count, 5, "Found 5 messages" );

# wipe the whole log file
$logite->clear(0);

is ( $logite->package_table->count, 0, "Found 0 messages (OK)" );
