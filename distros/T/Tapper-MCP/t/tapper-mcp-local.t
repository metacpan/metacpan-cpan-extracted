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



# (XXX) need to find a way to include log4perl into tests to make sure no
# errors reported through this framework are missed
my $string = "
log4perl.rootLogger           = INFO, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
Log::Log4perl->init(\$string);




# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_local.yml' );
# -----------------------------------------------------------------------------------------------------------------

my @errors;
my $mock_child = Test::MockModule->new('Tapper::MCP::Child');
$mock_child->mock('wait_for_testrun',   sub { 0 });
$mock_child->mock('report_mcp_results', sub { 0 });
$mock_child->mock('handle_error', sub { my ($self, $error_msg, $error_comment) = @_;
                                        push @errors, {msg => $error_msg,
                                                       comment => $error_comment}
                                });
my $child = Tapper::MCP::Child->new(13);
my $error = $child->runtest_handling();
is($error, 0, 'runtest_handling without error');
eval {
        is($child->state->state_details->state_details->{current_state}, 'reboot_test','local test with skipped installation');
};
is_deeply(\@errors, [], 'No errors during testing');
if (@errors) {
        use Data::Dumper;
        diag Dumper \@errors;
}
done_testing();
