# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 11;
use strict;
use warnings;
use lib qw(lib);

BEGIN { use_ok ( 'Net::Sieve' ); }

SKIP: {
	skip "set your own server, user, password to make tests", 10;

my $sieve = Net::Sieve->new ( 
    server => 'imap.server.org', 
    user => 'user', 
    password => 'pass', 
#    debug => 1,
#    ssl_verify => 0x00
    );

isa_ok ( $sieve, 'Net::Sieve' );


my $test_script='require "fileinto";
# Place all these in the "Test" folder
if header :contains "Subject" "[Test]" {
           fileinto "Test";
}
';

my $name_script = 'test';


# write
ok( $sieve->put($name_script,$test_script), "put script" );

# read test script by name
ok ( $sieve->get($name_script), "read script \"$name_script\"" );

ok ( $sieve->activate($name_script), "activate script \"$name_script\"" );

ok ( $sieve->deactivate(), "deactivate sieve processing" );

ok ( $sieve->activate($name_script), "activate script \"$name_script\"" );

my %Script;
foreach my $script ( $sieve->list() ) {
#    print $script->{name}." ".$script->{status}."\n";
    $Script{$script->{name}} = $script->{status};
};

ok ( $Script{$name_script}, "\"$name_script\" script active" );

ok ( $sieve->delete($name_script), "delete \"$name_script\" script" );

is ( $sieve->capabilities, "fileinto reject envelope vacation imapflags notify subaddress relational regex", "sieve script capabilities");

ok($sieve->sfinish(),"test end connection");

} #SKIP
