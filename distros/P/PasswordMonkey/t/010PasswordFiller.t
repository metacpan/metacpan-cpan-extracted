######################################################################
# Test suite for PasswordMonkey
######################################################################
use warnings;
use strict;

use Test::More;
use PasswordMonkey;
use FindBin qw($Bin);
use PasswordMonkey::Filler::Password;
use Log::Log4perl qw(:easy);

my $eg_dir = "$Bin/eg";

plan tests => 1;

my $pwfiller = PasswordMonkey::Filler::Password->new(
    password => "blech",
);

my $monkey = PasswordMonkey->new();
$monkey->filler_add( $pwfiller );

$monkey->spawn("$^X $Bin/eg/adduser-simulator");

$monkey->go();

my $rc = ($monkey->exit_status() >> 8);
is( $rc, 0, "adduser succeeded" );
