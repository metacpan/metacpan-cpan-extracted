######################################################################
# Test suite for PasswordMonkey
######################################################################
use warnings;
use strict;

use Test::More;
use PasswordMonkey;
use FindBin qw($Bin);
use PasswordMonkey::Filler::Sudo;
use PasswordMonkey::Bouncer::Retry;
use Log::Log4perl qw(:easy);
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $eg_dir = "$Bin/eg";

plan tests => 1;

my $retry_bouncer = PasswordMonkey::Bouncer::Retry->new(
    timeout => 5,
);

my $sudofiller = PasswordMonkey::Filler::Sudo->new(
    password => "blech",
);

$sudofiller->bouncer_add( $retry_bouncer );

my $monkey = PasswordMonkey->new();
$monkey->filler_add( $sudofiller );

$monkey->spawn("$^X $Bin/eg/sudo-simulator-twice");

$monkey->go();

my $rc = ($monkey->exit_status() >> 8);
is( $rc, 0, "adduser succeeded" );
