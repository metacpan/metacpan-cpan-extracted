use strict;
use warnings;
use 5.010;

##########################################################################
#                                                                        #
# Handling preconditions in virt guests was broken. Testprograms from    #
# the testprogram list were added multiple times (once for each          #
# precondition in precondition list (D'oh!), testprogram preconditions   #
# from precondition list were not added at all. This test program checks #
# that both issues are fixed and don't show up again.                    #
#                                                                        #
##########################################################################

use Test::More;
use English '-no_match_vars';
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;
use Tapper::Model 'model';
use File::Temp qw/ tempdir /;
use POSIX ":sys_wait_h"; # for nonblocking read
use Test::MockModule;

use Log::Log4perl;
use Tapper::MCP::Config;

        my $string = "
log4perl.rootLogger           = OFF, root
log4perl.appender.root        = Log::Log4perl::Appender::Screen
log4perl.appender.root.stderr = 1
log4perl.appender.root.layout = SimpleLayout";
        Log::Log4perl->init(\$string);


# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testrun_double.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $testrun = model('TestrunDB')->resultset('Testrun')->find(23);
my $conf_obj = Tapper::MCP::Config->new({testrun => $testrun});
my $config = $conf_obj->create_config;
is(int @{$config->{preconditions}->[35]->{config}->{testprogram_list}}, 5, 'Testprogram list in guest 2 not doubled');
is_deeply($config->{preconditions}->[34]->{config}->{testprogram_list}->[5], {runtime => 5,
                                                                              program => '/opt/tapper/bin/tapper_testsuite/py_edac',
                                                                              timeout => 900,
                                                                             },
          'Testprogram precondition in precondition list of guest handled correctly');

done_testing();
