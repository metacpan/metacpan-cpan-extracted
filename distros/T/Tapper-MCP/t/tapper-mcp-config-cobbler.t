#! /usr/bin/env perl

use strict;
use warnings;

use Test::MockModule;
use Test::Fixture::DBIC::Schema;
use Test::More tests => 8;

use Tapper::Schema::TestTools;


BEGIN { use_ok('Tapper::MCP::Config'); }

my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = PatternLayout
# date package category - message in  last 2 components of filename (linenumber) newline
log4perl.appender.root.layout.ConversionPattern = %d %p %c - %m in %F{2} (%L)%n";
Log::Log4perl->init(\$string);

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_cobbler.yml' );
# -----------------------------------------------------------------------------------------------------------------

my @commands;

my $mockcmd = Test::MockModule->new('Tapper::Cmd::Cobbler');
$mockcmd->mock('host_list', sub {my (undef, $condition) = @_; push @commands, { host_list => $condition }; return 'string'});
$mockcmd->mock('host_update', sub {my (undef, $condition) = @_; push @commands, { host_update => [$condition] }; return});
$mockcmd->mock('host_new', sub {my (undef, $name) = @_; push @commands, { host_new => $name }; return });

my $producer = Tapper::MCP::Config->new(1);
isa_ok($producer, "Tapper::MCP::Config", 'Producer object created');

my $config = $producer->create_config();
is(ref($config),'HASH', 'Config created');
is($config->{cobbler},'ubuntu-for-testing','Cobbler key in config');
is_deeply(\@commands, [ { host_list   => { name    => "iring"}},
                        { host_update => [{
                                           name    => "iring",
                                           profile => "ubuntu-for-testing",
                                           "netboot-enabled" => 1,
                                          }
                                         ]},
                      ], 'Commands to cobbler');

@commands = ();
$mockcmd->mock('host_list', sub {my (undef, $condition) = @_; push @commands, {host_list => $condition}; return });
$config = $producer->create_config();
is(ref($config),'HASH', 'Config created');
is($config->{cobbler},'ubuntu-for-testing','Cobbler key in config');
is_deeply(\@commands, [ { host_list => { name => "iring"}},
                        { host_new  => "iring"},
                        { host_update => [ {
                                            name    => "iring",
                                            profile =>   "ubuntu-for-testing",
                                            "netboot-enabled" => 1,
                                           }
                                         ]},
                      ], 'Commands to cobbler');

