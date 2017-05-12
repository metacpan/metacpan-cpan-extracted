#!perl
use strict;
use warnings;
use Test::More;
use lib "t/lib";
use Utils;


plan tests => 7;

my $module = "SNMP::Extension::PassPersist";

# input data
my ($oid, $type, $value) = qw<.1.2.3 integer 42>;
my $input = "";
my @args  = (-g => $oid);

# expected data
my %expected_tree = (
    $oid => [ $type => $value ],
);
my $expected_output = join "\n", $oid, $type, $value, "";

# load the module
use_ok($module);

# create the object
my $extsnmp = eval { $module->new };
is( $@, "", "$module->new" );
isa_ok( $extsnmp, $module, "check that \$extsnmp" );

# add an OID entry
eval { $extsnmp->add_oid_entry($oid, $type, $value) };
is( $@, "", "add_oid_entry('$oid', '$type', '$value')" );
is_deeply( $extsnmp->oid_tree, \%expected_tree, "check internal OID tree consistency" );

# execute the main loop
local @ARGV = @args;
my ($stdin, $stdout) = ( ro_fh(\$input), wo_fh(\my $output) );
$extsnmp->input($stdin);
$extsnmp->output($stdout);
eval { $extsnmp->run };
is( $@, "", "\$extsnmp->run" );
is( $output, $expected_output, "check the output" );
