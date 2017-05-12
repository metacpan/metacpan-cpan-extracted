######################################################################
# Test suite for PasswordMonkey
######################################################################
use warnings;
use strict;

use Test::More;
use PasswordMonkey;
use FindBin qw($Bin);
use PasswordMonkey::Filler::Sudo;;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init($DEBUG);

  # debug on
# $Expect::Exp_Internal = 1;

my $eg_dir = "$Bin/eg";

plan tests => 3;

my $sudo = PasswordMonkey::Filler::Sudo->new(
    password => "supersecrEt",
);

my $monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );
$monkey->filler_add( $sudo );
$monkey->spawn("$^X /does/not/exist/anywhere");
$monkey->go();
my $rc = ($monkey->exit_status() >> 8);
isnt( $rc, 0, "failed perl script" );

$monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );
$monkey->filler_add( $sudo );
$monkey->spawn("$^X $Bin/eg/ex0");
$monkey->go();
$rc = ($monkey->exit_status() >> 8);
is( $rc, 0, "ok perl rc" );

$monkey = PasswordMonkey->new();
$monkey->{expect}->log_user( 0 );
$monkey->filler_add( $sudo );
$monkey->spawn("$^X $Bin/eg/ex69");
$monkey->go();
$rc = ($monkey->exit_status() >> 8);
is( $rc, 69, "exit code 69" );
