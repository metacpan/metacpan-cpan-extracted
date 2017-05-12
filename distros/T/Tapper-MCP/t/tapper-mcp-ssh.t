#!/usr/bin/env perl
use strict;
use warnings;

use Test::Fixture::DBIC::Schema;
use Test::MockModule;
use Tapper::MCP::Child;
use Tapper::Schema::TestTools;
use Tapper::Config;

use Test::More;


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_with_preconditions.yml' );
# -----------------------------------------------------------------------------------------------------------------

# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);

my $default_config = Tapper::Config->subconfig;


my @commands;
my $mock_scp = Test::MockModule->new('Net::SCP');
my $mock_ssh = Test::MockModule->new('Net::SSH');
$mock_scp->mock('put', sub { my (undef, @params) = @_; push @commands, {put => \@params}; 1; });
$mock_ssh->mock('ssh', sub { my (@params) = @_; push @commands, {ssh => \@params}; 0;}); # Net::SSH doesn't offer OO interface

my $child = Tapper::MCP::Child->new(114);
my $retval = $child->generate_configs('nosuchhost');
is(ref $retval, 'HASH', 'Got config');
is_deeply($retval->{preconditions}->[0],
          {
           'config' => {'testprogram_list' => [{
                                                'runtime' => '30',
                                                'timeout' => '90',
                                                'program' => '/bin/uname_tap.sh'
                                               }
                                              ],
                        'guest_number' => 0,

                       },
           'precondition_type' => 'prc',
           'skip_startscript' => 1
          }, 'Config for PRC');


$child->start_testrun($retval);

my $mcp_host    = $default_config->{mcp_host};
my $prc_program = $default_config->{files}{tapper_prc};
my $path        = $default_config->{paths}{package_dir};
$path          =~ s|/$||;
is_deeply(shift @commands,
          {
           'put' => [ "$path/tapperutils/opt-tapper64.tar.gz",
                      '/dev/shm/tmp/tapper-clientpkg.tgz'] },
          'Copy clientpackage');
is_deeply(shift @commands,
          {
           'ssh' => ['nosuchhost','tar -xzf /dev/shm/tmp/tapper-clientpkg.tgz -C /']},
          'Unpack client package');
is_deeply(shift @commands,
          {
           'ssh' => ["nosuchhost","TAPPER_TEST_TYPE=ssh $prc_program --host $mcp_host"]},
          'Start PRC in autoinstall mode');

done_testing();
