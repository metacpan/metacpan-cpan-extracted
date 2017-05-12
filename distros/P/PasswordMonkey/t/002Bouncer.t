######################################################################
# Test suite for PasswordMonkey
######################################################################
use warnings;
use strict;

use Test::More;
use PasswordMonkey;
use FindBin qw($Bin);
use PasswordMonkey::Filler::Sudo;
use PasswordMonkey::Bouncer::Wait;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

  # debug on
# $Expect::Exp_Internal = 1;

my $eg_dir = "$Bin/eg";

plan tests => 2;

my $sudo = PasswordMonkey::Filler::Sudo->new(
    password => "supersecrEt",
);

my $waiter = PasswordMonkey::Bouncer::Wait->new(
    seconds => 1,
);

$sudo->bouncer_add( $waiter );

my $monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );

$monkey->filler_add( $sudo );

$monkey->spawn("$^X $eg_dir/sudo-simulator echo foo");

my $rc = $monkey->go();

like( $monkey->expect()->match(), qr/password for/, "sudo simulator" );
is $rc, 1, "monkey succeeded";
