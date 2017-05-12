use Test::More qw(); 
#Don't import anything or test routines become potential matches during the test

use Symbol::Approx::Sub (
    xform => undef,
    match => undef
);

sub aa { 'aa' }

sub bb { 'bb' }

sub cc { 'cc' }

my $total_tries = 1000;
my $tries_left = $total_tries;

my %remaining_returns = (
    'aa' => 1,
    'bb' => 1,
    'cc' => 1,
);

while($tries_left >= 0) {
    my $ret_val = b();
    delete $remaining_returns{$ret_val};
    last if !keys %remaining_returns;
    $tries_left--;
}

Test::More::ok !keys %remaining_returns, "Got all expected return values (covering all our subroutines) in <= $total_tries tries";

Test::More::done_testing();
