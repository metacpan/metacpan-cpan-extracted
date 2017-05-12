
use ExtUtils::MakeMaker;

my $CONFIG_MODE = 0600;
my $CONFIG_FILE = "config.cache";

WriteMakefile(
    NAME		=> 'POE::Component::SNMP',
    VERSION_FROM	=> 'lib/POE/Component/SNMP.pm',
    (LICENSE            => 'perl') x ($ExtUtils::MakeMaker::VERSION >= 6.31),

    PREREQ_PM		=> { 'POE' => 0.31, 'Net::SNMP' => 0, 'Time::HiRes' => 0 },
    (AUTHOR     => 'Rob Bloodgood <rob@exitexchange.com>') x ($] >= 5.005),
);

exit 0 if -e $CONFIG_FILE;


my $DEBUG_FLAG = 0x00; # none
# my $DEBUG_FLAG = 0x08; # dispatcher
# my $DEBUG_FLAG = 0x0A; # transport+dispatcher
# my $DEBUG_FLAG = 0x1A; # transport+dispatcher+message processing
# my $DEBUG_FLAG = 0xFF; # everything

print "The test suite requires access to an SNMP agent.\n";
my $hostname = prompt("enter a hostname [leave empty to skip all tests]");

if ($hostname) {
    my $rcomm    = prompt("enter read community string", 'public');
    my $wcomm    = prompt("enter write community string [leave empty to skip write tests]");

    print "creating $CONFIG_FILE\n";
    open TESTCONF, "> $CONFIG_FILE" or die "can't create $CONFIG_FILE: $!\n";
    print TESTCONF <<CONFIGURATION;
 \$CONF = {
    hostname   => '$hostname',
    community  => '$rcomm',
    wcommunity => '$wcomm',
    debug      => $DEBUG_FLAG,
 };
CONFIGURATION
    close TESTCONF or die "can't close $CONFIG_FILE: $!\n";
} else {
    print "creating $CONFIG_FILE\n";
    open TESTCONF, "> $CONFIG_FILE" or die "can't create $CONFIG_FILE: $!\n";
    print TESTCONF "\$TEST_CONF = { skip_all_tests => 1 };\n";
    close TESTCONF or die "can't close $CONFIG_FILE: $!\n";
}

chmod $CONFIG_MODE, $CONFIG_FILE;

exit 0;

# extra targets for realclean to delete the config file
package MY;
sub macro { "CONFIG_FILE = $CONFIG_FILE" }
sub realclean {
    shift->SUPER::realclean(@_) .
      qq[\t- \$(RM_F) \$(CONFIG_FILE)] # don't forget \t here!
}
