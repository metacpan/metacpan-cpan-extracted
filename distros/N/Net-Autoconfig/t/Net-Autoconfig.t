# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Autoconfig.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 45;
#use Cwd;
BEGIN { use_ok('Net::Autoconfig') };

#my $PATH = getcwd();

# These should match the ones in Net::Autoconfig
use constant TRUE                 => 1;
use constant FALSE                => 0;
use constant DEFAULT_MAX_CHILDREN => 64;
use constant MAXIMUM_MAX_CHILDREN => 256;
use constant MINIMUM_MAX_CHILDREN => 1;

use constant DEFAULT_LOGFILE      => '/usr/local/etc/autoconfig/logging.conf';

use constant MAX_LOG_LEVEL        => 5;
use constant DEFAULT_LOG_LEVEL    => 3;
use constant MIN_LOG_LEVEL        => 0;

use constant DEFAULT_BULK_MODE    => TRUE;


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########################
# Test all public methods
my @public_methods = qw(    new bulk_mode log_level max_children load_devices
                            load_template autoconfig get_report logfile init_logging
                            _get_password
                            );
can_ok("Net::Autoconfig", @public_methods);

#########################
# Test all private methods
my @private_methods = qw(_file_not_usable _failed_ping_test _reaper);
can_ok("Net::Autoconfig", @private_methods);



####################
# Keep logging output from going to the screen
# Aka capture STDERR and then restore it
# I wonder if this is a bad idea...
####################
my $old_stderr = *STDERR;
open(NULL, ">/dev/null")
    || die print "Could not open '/dev/null for writing: $!";
*STDERR = *NULL;
####################


########################################
# Testing New Method
########################################
is(ref(Net::Autoconfig->new()), "Net::Autoconfig", "Testing for correct Net::Autoconfig->new method call");
my $autoconf = Net::Autoconfig->new();

########################################
# Testing Accessor/Mutator methods
########################################

is($autoconf->max_children, DEFAULT_MAX_CHILDREN, "Default max children");
is($autoconf->max_children(12), undef, "Setting max children to something reasonable");
is($autoconf->max_children, 12, "Maximum max children");
is($autoconf->max_children(512), undef, "Setting max children excessivly high");
is($autoconf->max_children, MAXIMUM_MAX_CHILDREN, "Maximum max children");
is($autoconf->max_children(0), undef, "Setting max children excessivly low");
is($autoconf->max_children, MINIMUM_MAX_CHILDREN, "Minimum max children");

is($autoconf->log_level, DEFAULT_LOG_LEVEL, "Default log level");
is($autoconf->log_level(2), undef, "Setting log level to something reasonable");
is($autoconf->log_level, 2, "After setting log level");
is($autoconf->log_level(27), undef, "Setting excessivly high log level");
is($autoconf->log_level, MAX_LOG_LEVEL, "After setting log level");
is($autoconf->log_level(-1), undef, "Setting excessivly high low level");
is($autoconf->log_level, MIN_LOG_LEVEL, "After setting log level");

is($autoconf->bulk_mode, DEFAULT_BULK_MODE, "Default bulk mode");
is($autoconf->bulk_mode(FALSE), undef, "Setting bulk mode to ! default");
is($autoconf->bulk_mode, FALSE, "Not Default bulk mode");
is($autoconf->bulk_mode("asdf"), undef, "Setting bulk mode to something true-ish");
is($autoconf->bulk_mode, TRUE, "True bulk mode");
is($autoconf->bulk_mode(0), undef, "Setting bulk mode to something false-ish");
is($autoconf->bulk_mode, FALSE, "False bulk mode");


is($autoconf->logfile, DEFAULT_LOGFILE, "Checking for default logfile"
                                           . " accessor method output");
is($autoconf->logfile('t/logging.conf'), undef, "Checking for logfile"
                                                . " assignment.");
is($autoconf->logfile('BOGUS'), undef, "Checking for assignment to"
                                                . " an invalid logfile.");
is($autoconf->logfile(), DEFAULT_LOGFILE, "Checking for assignment to"
                                                . " an invalid logfile.");

####################
# Restore stderr
####################
*STDERR = $old_stderr;
close(NULL);

is($autoconf->logfile('t/logging.conf'), undef, "Using the default"
                                                . " logging.conf file");
is($autoconf->init_logging(), undef, "Reinitializing logging");
####################


########################################
# Testing Devices
########################################
my $devices;
my @devices;

ok(! Net::Autoconfig->load_devices(), "Testing for null input to load_devices");
ok(Net::Autoconfig->load_devices("t/devices.cfg"), "Testing loading a device config file");

# Test device config file
$devices = $autoconf->load_devices("t/devices.cfg");
@devices = $autoconf->load_devices("t/devices.cfg");
is(ref($devices), "ARRAY", "Testing scalar context for get devices");
is(ref(@devices), "", "Testing array context of get devices");

########################################
# Testing Templates
########################################
my $template;
my %template;

is($autoconf->load_template(), undef, "Testing null filename test case for load template.");
is(ref($autoconf->load_template("t/template.cfg")), 'Net::Autoconfig::Template', "Testing valid filename for load template.");

$template = $autoconf->load_template("t/template.cfg");
is(ref($template), "Net::Autoconfig::Template", "Testing scalar context for load_template");

########################################
# Testing autoconfig
########################################

ok($autoconf->autoconfig(), "null input to autoconfig, should return true aka failure");
ok($autoconf->autoconfig("asdf",undef), "null input to autoconfig, should return true aka failure");
like( $autoconf->autoconfig("asdf"), qr/Devices were not passed as an array ref/, "Non-array ref passed for devices");
like( $autoconf->autoconfig([]), qr/No template passed to autoconfig/, "Non template passed");

########################################
# Testing get_report
########################################

ok($autoconf->get_report, "Testing for some sort of output from get_report");
{
	my @temp = $autoconf->get_report();
	my $temp = $autoconf->get_report();
	is(ref(@temp), '', "Testing for array context output from get_report");
	is(ref($temp), 'HASH', "Testing for scalar context output from get_report");
}
