#!perl
use strict;
use warnings;
use Test::More;
use lib "t/lib";


plan skip_all => "doesn't work under Win32" if $^O =~ /Win32/;
plan skip_all => "JSON not available"       unless eval "use JSON; 1";
plan skip_all => "IPC::Run not available"   unless eval "use IPC::Run; 1";

# use JSON v2 API even with JSON v1
if (JSON->VERSION < 2.00) {
    no warnings;
    *to_json   = *JSON::encode = \&JSON::objToJson;
    *from_json = *JSON::decode = \&JSON::jsonToObj;
}

plan tests => 3;

my @expected = (
    { oid => ".1.2.42.1",  type => "integer",  value => "42", },
    { oid => ".1.2.42.2",  type => "string",   value => "the answer", },
);

my $walker  = "eg/pseudo-walk";
my $snmpext = "eg/synopsis-passpersist.pl";
my @cmd = ( $^X, $walker, "--as", "json", "--", ".1.2.42", $^X, "-Ilib", $snmpext );
my ($in, $out, $err) = ("", "", "");

# execute the SNMP extension
my $r = IPC::Run::run(\@cmd, \$in, \$out, \$err);
ok( $r, "run(@cmd)" ) or diag "exec error: $err";

# decode the JSON output
$out =~ s/[\x00-\x1f]//g;  # remove all control chars
my $tree = eval { from_json($out) };
is( $@, "", "decode the JSON output" );

# check the structure
is_deeply( $tree, \@expected, "check the structure" );

