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

plan tests => 2;

my $monkey = PasswordMonkey->new( timeout => 1 );
$monkey->expect->log_user( 0 );

$monkey->spawn("$^X $eg_dir/timeout");
$monkey->go();

ok $monkey->timed_out, "monkey timed out";
ok !$monkey->is_success, "monkey failed";
