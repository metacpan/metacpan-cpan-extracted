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
use Expect;
use Data::Dumper;

# Log::Log4perl->easy_init({ level => $DEBUG, layout => "%F{1}:%L %m%n" });

  # debug on
# $Expect::Exp_Internal = 1;

  # suppress warnings because bouncer's gonna warn
local $SIG{__WARN__}=sub{};

my $eg_dir = "$Bin/eg";

plan tests => 3;

my $sudo = PasswordMonkey::Filler::Sudo->new(
    password => "supersecrEt",
);

my $waiter = PasswordMonkey::Bouncer::Wait->new(
    seconds => 2,
);

$sudo->bouncer_add( $waiter );

my $monkey = PasswordMonkey->new(
    # timeout => 5,
);

$monkey->{expect}->log_user( 0 );

$monkey->filler_add( $sudo );

$monkey->spawn("$^X $eg_dir/sudo-simulator-fake echo foo");

my $rc = $monkey->go();

unlike $monkey->{expect_return}->{before_match}, 
     qr/supersecrEt/, "no passwd in output";

is $rc, 1, "program succeeded";
is $monkey->fills(), 0, "0 fills";
