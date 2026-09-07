#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'Punk::Command required'
        unless eval { require Punk::Command; Punk::Command->can('main') };
}

use Punk::Challenge::Token ();

# `punk challenge`, in process through Punk::Command's test seam: neither
# verb loads an application, so nothing compiles twice.

sub run_punk {
    my (@argv) = @_;
    my ($out, $err) = ('', '');
    open my $ofh, '>', \$out or die $!;
    open my $efh, '>', \$err or die $!;
    local $Punk::Command::OUT = $ofh;
    local $Punk::Command::ERR = $efh;
    my $rc = Punk::Command->main(@argv);
    close $ofh;
    close $efh;
    return ($rc, $out, $err);
}

# ---- the command is found by name, without a prior require -----------------------

{
    my ($rc, $out, $err) = run_punk('challenge', 'key');
    is($rc, 0, 'punk challenge key exits 0') or diag $err;
    like($out, qr/^[A-Za-z0-9_-]{43}\n\z/, '  and prints 43 characters of base64url');
    my (undef, $out2) = run_punk('challenge', 'key');
    isnt($out2, $out, '  and a second key differs');
    ok($INC{'Punk/Command/Challenge.pm'}, '  having loaded the module on first use');
}

like(Punk::Challenge::Token->key, qr/^[A-Za-z0-9_-]{43}\z/, 'Token->key is what it prints');

# ---- solve ---------------------------------------------------------------------------

{
    my %cfg = ( secret => 'k', bits => 8 );
    my $S = '192.0.2.0/24';
    my $puzzle = Punk::Challenge::Token->issue(\%cfg, $S);
    my ($rc, $out, $err) = run_punk('challenge', 'solve', $puzzle);
    is($rc, 0, 'punk challenge solve exits 0') or diag $err;
    chomp $out;
    is(scalar Punk::Challenge::Token->verify(\%cfg, $S, $out), 8, '  and prints a solution that verifies');
    like($err, qr/solving at 8 bits: about 256 hashes/, '  saying what it expected first');
}

{
    my ($rc, $out, $err) = run_punk('challenge', 'solve');
    isnt($rc, 0, 'solve without a puzzle is a usage error');
    like($err, qr/punk challenge solve <puzzle>/, '  that shows the usage');
    ($rc, $out, $err) = run_punk('challenge', 'solve', 'hello');
    isnt($rc, 0, 'solve of a non-puzzle fails');
    like($err, qr/not a puzzle: hello/, '  and says so');
    my $p23 = 'v1.1725600000.23.k3x-2f.' . ('A' x 22);
    ($rc, $out, $err) = run_punk('challenge', 'solve', $p23);
    isnt($rc, 0, 'twenty-three bits is refused');
    like($err, qr/above the 22/, '  and says why');
    is($out, '', '  and prints nothing');
}

{
    my ($rc, $out, $err) = run_punk('challenge');
    like($out . $err, qr/key.*solve|solve.*key/s, 'punk challenge alone lists its verbs');
}

done_testing;
