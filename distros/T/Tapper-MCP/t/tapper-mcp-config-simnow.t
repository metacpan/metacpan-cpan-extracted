#! /usr/bin/env perl

use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use YAML::Syck;

use Tapper::Schema::TestTools;
use Tapper::MCP::Child;
use Tapper::Config;

use Test::More;
use Test::Deep;
use Test::MockModule;
use Sys::Hostname;
use Socket;

BEGIN { use_ok('Tapper::MCP::Config'); }


# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);


sub msg_send
{
        my ($yaml, $port) = @_;
        my $remote = IO::Socket::INET->new(PeerHost => 'localhost',
                                           PeerPort => $port) or return "Can't connect to server:$!";
        print $remote $yaml;
        close $remote;
}

sub closure
{
        my ($file) = @_;
        my $i=0;
        my @data = LoadFile($file);
        return sub{my ($self, $file) = @_; return $data[$i++]};
}


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_simnow.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $producer = Tapper::MCP::Config->new(1);
isa_ok($producer, "Tapper::MCP::Config", 'Producer object created');

my $config = $producer->create_config(12);
is(ref($config),'HASH', 'Config created');

is(int @{$config->{preconditions}}, 4, '3 preconditions for simnow');
is($config->{files}{simnow_script}, 'family10_sles10_xen.simnow', 'Simnow script set');

done_testing();
