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

  # suppress warnings because bouncer's gonna warn
local $SIG{__WARN__}=sub{};

plan tests => 15;

my $sudo = PasswordMonkey::Filler::Sudo->new(
    password => "supersecrEt",
);

my $monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );

$monkey->filler_add( $sudo );

$monkey->spawn("$^X $eg_dir/sudo-simulator-twice");

my $rc = $monkey->go();

is $rc, 1, "succeeded";
is $monkey->fills(), 2, "2 fills";

  # Expect doesn't allow reuse of objects with spawned commands, even
  # if the command has existed. Allocate a new one.
$monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );
$monkey->filler_add( $sudo );

my $waiter = PasswordMonkey::Bouncer::Wait->new(
    seconds => 2,
);

$sudo->bouncer_add( $waiter );

$monkey->spawn("$^X $eg_dir/sudo-simulator-twice");

$rc = $monkey->go();
is $rc, 1, "succeeded";
is $monkey->fills(), 2, "2 fills";

like $monkey->{expect_return}->{before_match}, qr/Got it \(2\)/,
    "twice waiting for 2 secs";

my $r = $monkey->{filler_report};

is $r->[0]->[0], '[sudo] password for womper:', "report ok";
is $r->[1]->[0], '[sudo] password for womper:', "report ok";

is $r->[0]->[1], 'supersecrEt', "report ok";
is $r->[1]->[1], 'supersecrEt', "report ok";

  # Expect doesn't allow reuse of objects with spawned commands, even
  # if the command has existed. Allocate a new one.
$monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );
$monkey->filler_add( $sudo );

$waiter = PasswordMonkey::Bouncer::Wait->new(
    seconds => 2,
);

$sudo->bouncer_add( $waiter );

$monkey->spawn("$^X $eg_dir/sudo-simulator-continue");

$rc = $monkey->go();
is($rc, 1, "succeeded");
is $monkey->fills(), 2, "2 fills";

$r = $monkey->{filler_report};

is $r->[0]->[0], '[sudo] password for womper:', "report ok";
is $r->[1]->[0], '[sudo] password for womper:', "report ok";

is $r->[0]->[1], 'supersecrEt', "report ok";
is $r->[1]->[1], 'supersecrEt', "report ok";
