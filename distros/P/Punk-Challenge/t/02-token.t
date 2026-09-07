#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

# Where the security lives: every field of a puzzle and a clearance, edited,
# must fail, and fail on the check that is supposed to catch it.
#
# Difficulty is eight bits throughout: 256 hashes on average, so nothing here
# depends on how fast the box is.

my $T = Punk::Challenge::Token::;
my $NOW = 1_725_600_000;
my %cfg = ( secret => 'k', bits => 8, ttl => 3600, puzzle_ttl => 300 );
my $S = '192.0.2.0/24';

sub verify  { my ($cfg, $subj, $sol, %o) = @_; my @r = $T->verify($cfg, $subj, $sol, undef, now => $NOW, %o); @r }
sub cleared { my ($cfg, $subj, $val, %o) = @_; my @r = $T->cleared($cfg, $subj, $val, now => $NOW, %o); @r }

# ---- subject ------------------------------------------------------------------

is($T->subject('192.0.2.7'),              '192.0.2.0/24', 'IPv4 prefix is the /24');
is($T->subject('192.0.2.200'),            '192.0.2.0/24', '  and a neighbour shares it');
is($T->subject('198.51.100.7'),           '198.51.100.0/24', '  a different /24 differs');
is($T->subject('192.0.2.7', 'ip'),        '192.0.2.7',    'ip is the address');
is($T->subject('192.0.2.7', 'none'),      '',             'none is nothing');
is($T->subject('2001:db8:1:2:3:4:5:6'),   '2001:db8:1:2::/64', 'IPv6 prefix is the /64');
is($T->subject('2001:db8:1:2::1'),        '2001:db8:1:2::/64', '  a compressed address in the same /64');
is($T->subject('2001:db8:1:3::1'),        '2001:db8:1:3::/64', '  a different /64 differs');
is($T->subject('::1'),                    '0:0:0:0::/64',      '  loopback');
is($T->subject('::ffff:192.0.2.7'),       '0:0:0:0::/64',      '  a mapped IPv4 parses');
is($T->subject('2001:DB8::1'),            '2001:db8:0:0::/64', '  case does not matter');
is($T->subject('fe80::1'),                'fe80:0:0:0::/64',   '  a leading group then a gap');
is($T->subject('1::'),                    '1:0:0:0::/64',      '  a trailing gap');
is($T->subject('not-an-address'),         'not-an-address',    'other text is used as given');
is($T->subject(''),                       '',                  'no address is the empty subject');
is($T->subject('unix:/tmp/sock'),         'unix:/tmp/sock',    '  as is a socket path');
for my $bad ('1:::2', '1:2:3:4:5:6:7:8:9', '::1::', '1:2:3:4:5:6:7', '12345::', 'g::1', '1:', ':1') {
    is($T->subject($bad), $bad, "'$bad' is not IPv6 and is used as given");
}
is($T->subject('256.0.0.1'), '256.0.0.1', 'a dotted quad over 255 is not IPv4');
is($T->subject('1.2.3'),     '1.2.3',     '  nor three groups');
is($T->subject('1.2.3.4.5'), '1.2.3.4.5', '  nor five');
{
    local $@;
    eval { $T->subject('1.2.3.4', 'header') };
    like($@, qr/`bind` must be 'prefix', 'ip' or 'none'/, 'an unknown bind croaks');
}

# ---- issue ---------------------------------------------------------------------

my $puzzle = $T->issue(\%cfg, $S, now => $NOW);
like($puzzle, qr/^v1\.\Q$NOW\E\.8\.[0-9a-z]+-[0-9a-z]+\.[A-Za-z0-9_-]{22}\z/,
    'a puzzle has the wire shape');
my $puzzle2 = $T->issue(\%cfg, $S, now => $NOW);
isnt($puzzle2, $puzzle, 'two puzzles in the same second differ');
my ($ts, $bits, $salt, $mac) = (split /\./, $puzzle)[1..4];

{
    my $msg = "puzzle\0$S\0$ts\0$bits\0$salt";
    my $want = Punk::Challenge::Token::_b64url(
        substr(Punk::Challenge::Token::_hmac_sha256('k', $msg), 0, 16));
    is($mac, $want, 'the MAC is the documented formula');
}

is($T->issue(\%cfg, $S, bits => 12) =~ /^v1\.\d+\.12\./ ? 1 : 0, 1, 'bits is overridable');
{
    local $@;
    eval { $T->issue(\%cfg, $S, bits => 23) };
    like($@, qr/`bits` must be between 1 and 22/, '  within the ceiling');
    eval { $T->issue({ bits => 8 }, $S) };
    like($@, qr/`secret` is required/, 'the configuration is validated as the plugin line is');
    eval { $T->issue(\%cfg, $S, bitz => 8) };
    like($@, qr/unknown option 'bitz' \(known: bits, now\)/, 'an unknown option croaks');
}

# ---- a correct solution ----------------------------------------------------------

my $solution = Punk::Challenge::Solver::solve($puzzle);
like($solution, qr/^\Q$puzzle\E\.\d+\z/, 'the solver appends a nonce');
my ($nonce) = $solution =~ /\.(\d+)\z/;

is_deeply([ verify(\%cfg, $S, $solution) ], [ 8, 'ok' ], 'the solution verifies at 8 bits');
is_deeply([ $T->verify(\%cfg, $S, $puzzle, $nonce, now => $NOW) ], [ 8, 'ok' ],
    '  and as puzzle plus nonce');
is(scalar $T->verify(\%cfg, $S, $solution, undef, now => $NOW), 8,
    '  scalar context is the bits');
is_deeply([ verify(\%cfg, $S, $solution, bits => 8) ], [ 8, 'ok' ], '  demanding 8 passes');
is_deeply([ verify(\%cfg, $S, $solution, bits => 9) ], [ undef, 'bits' ],
    '  demanding 9 is refused on bits, before the hash');
is_deeply([ verify(\%cfg, $S, $solution, bits => 1) ], [ 8, 'ok' ], '  demanding 1 passes');
{
    my $live = $T->issue(\%cfg, $S);
    my $ls = Punk::Challenge::Solver::solve($live);
    is_deeply([ $T->verify(\%cfg, $S, $ls) ], [ 8, 'ok' ],
        'without now, issue and verify agree on the real clock');
}

# ---- every field, edited ------------------------------------------------------------

sub edited {
    my ($sol, $field, $to) = @_;
    my @f = split /\./, $sol;
    $f[$field] = $to;
    return join '.', @f;
}

# ts
is_deeply([ verify(\%cfg, $S, $solution, now => $NOW + 300) ], [ 8, 'ok' ],
    'at exactly puzzle_ttl it is fresh');
is_deeply([ verify(\%cfg, $S, $solution, now => $NOW + 301) ], [ undef, 'stale' ],
    'a second past puzzle_ttl it is stale');
is_deeply([ verify(\%cfg, $S, $solution, now => $NOW - 60) ], [ 8, 'ok' ],
    'sixty seconds in the future is allowed');
is_deeply([ verify(\%cfg, $S, $solution, now => $NOW - 61) ], [ undef, 'future' ],
    'sixty-one is not');
is_deeply([ verify(\%cfg, $S, edited($solution, 1, $ts - 1)) ], [ undef, 'mac' ],
    'ts moved fails the MAC');
is_deeply([ verify(\%cfg, $S, edited($solution, 1, 'x')) ],   [ undef, 'shape' ],
    'ts not decimal is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 1, '')) ],    [ undef, 'shape' ],
    'ts empty is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 1, '1' x 20)) ], [ undef, 'shape' ],
    'ts too long is not a token');

# bits: lowered is the important one - a client that could lower bits would
# pay nothing, and the MAC is what stops it
is_deeply([ verify(\%cfg, $S, edited($solution, 2, 7), bits => 1) ],  [ undef, 'mac' ],
    'bits lowered fails the MAC, not the hash');
is_deeply([ verify(\%cfg, $S, edited($solution, 2, 9)) ],  [ undef, 'mac' ],
    'bits raised fails the MAC');
is_deeply([ verify(\%cfg, $S, edited($solution, 2, 0)) ],  [ undef, 'shape' ],
    'bits 0 is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 2, 23)) ], [ undef, 'shape' ],
    'bits 23 is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 2, 'x')) ], [ undef, 'shape' ],
    'bits not decimal is not a token');

# salt
is_deeply([ verify(\%cfg, $S, edited($solution, 3, $salt . 'z')) ], [ undef, 'mac' ],
    'salt changed fails the MAC');
is_deeply([ verify(\%cfg, $S, edited($solution, 3, '')) ], [ undef, 'shape' ],
    'salt empty is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 3, 'A')) ], [ undef, 'shape' ],
    'salt outside its alphabet is not a token');

# mac
{
    my $flip = $mac;
    substr($flip, 5, 1) = substr($flip, 5, 1) eq 'A' ? 'B' : 'A';
    is_deeply([ verify(\%cfg, $S, edited($solution, 4, $flip)) ], [ undef, 'mac' ],
        'one character of the MAC changed fails the MAC');
}
is_deeply([ verify(\%cfg, $S, edited($solution, 4, substr($mac, 0, 21))) ], [ undef, 'shape' ],
    'a truncated MAC is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 4, '')) ], [ undef, 'shape' ],
    'an empty MAC is not a token');
is_deeply([ verify(\%cfg, $S, edited($solution, 4, $mac . 'A')) ], [ undef, 'shape' ],
    'an overlong MAC is not a token');

# nonce
is_deeply([ verify(\%cfg, $S, edited($solution, 5, $nonce + 1)) ], [ undef, 'hash' ],
    'a wrong nonce fails the hash') if ($nonce + 1) !~ /^0/;
is_deeply([ verify(\%cfg, $S, edited($solution, 5, 'x')) ], [ undef, 'shape' ],
    'a nonce that is not decimal is not a token');
is_deeply([ verify(\%cfg, $S, $puzzle) ], [ undef, 'shape' ],
    'a puzzle with no nonce is not a solution');
is_deeply([ verify(\%cfg, $S, "$solution.1") ], [ undef, 'shape' ],
    'an extra field is not a solution');

# the whole thing
is_deeply([ verify(\%cfg, $S, '') ],    [ undef, 'shape' ], 'nothing is not a solution');
is_deeply([ verify(\%cfg, $S, 'v2' . substr($solution, 2)) ], [ undef, 'shape' ],
    'another version is not a solution');
is_deeply([ verify(\%cfg, $S, 'x' x 200) ], [ undef, 'shape' ],
    'an oversize string is refused before anything looks inside');

# ---- subject binding ------------------------------------------------------------

is_deeply([ verify(\%cfg, '198.51.100.0/24', $solution) ], [ undef, 'mac' ],
    'a valid solution from a different subject fails the MAC');
{
    my %pfx = (%cfg, bind => 'prefix');
    my %ip  = (%cfg, bind => 'ip');
    my $a = $T->subject('192.0.2.7');
    my $b = $T->subject('192.0.2.200');
    my $p = $T->issue(\%pfx, $a, now => $NOW);
    my $s = Punk::Challenge::Solver::solve($p);
    is($a, $b, 'under prefix, two addresses in one /24 are one subject');
    is_deeply([ verify(\%pfx, $b, $s) ], [ 8, 'ok' ], '  so one solves for the other');
    my $ia = $T->subject('192.0.2.7', 'ip');
    my $ib = $T->subject('192.0.2.200', 'ip');
    my $ip_p = $T->issue(\%ip, $ia, now => $NOW);
    my $ip_s = Punk::Challenge::Solver::solve($ip_p);
    is_deeply([ verify(\%ip, $ia, $ip_s) ], [ 8, 'ok' ], 'under ip, the issuing address verifies');
    is_deeply([ verify(\%ip, $ib, $ip_s) ], [ undef, 'mac' ], '  and its neighbour does not');
    my $c = $T->subject('198.51.100.7');
    is_deeply([ verify(\%pfx, $c, $s) ], [ undef, 'mac' ], 'a different /24 fails under prefix');
    my $v6a = $T->subject('2001:db8:1:2::1');
    my $v6b = $T->subject('2001:db8:1:2:ffff::1');
    my $v6c = $T->subject('2001:db8:1:3::1');
    my $p6 = $T->issue(\%pfx, $v6a, now => $NOW);
    my $s6 = Punk::Challenge::Solver::solve($p6);
    is_deeply([ verify(\%pfx, $v6b, $s6) ], [ 8, 'ok' ], 'IPv6: one /64 is one subject');
    is_deeply([ verify(\%pfx, $v6c, $s6) ], [ undef, 'mac' ], '  and another /64 is not');
}

# ---- rotation -------------------------------------------------------------------

{
    my %old = (%cfg, secret => ['old']);
    my %both = (%cfg, secret => ['new', 'old']);
    my %new = (%cfg, secret => ['new']);
    my $p = $T->issue(\%old, $S, now => $NOW);
    my $s = Punk::Challenge::Solver::solve($p);
    is_deeply([ verify(\%old, $S, $s) ],  [ 8, 'ok' ],     'issued under old verifies under old');
    is_deeply([ verify(\%both, $S, $s) ], [ 8, 'ok' ],     '  and under [new, old]');
    is_deeply([ verify(\%new, $S, $s) ],  [ undef, 'mac' ], '  and not under [new]');
    my $p2 = $T->issue(\%both, $S, now => $NOW);
    my $s2 = Punk::Challenge::Solver::solve($p2);
    is_deeply([ verify(\%new, $S, $s2) ], [ 8, 'ok' ],  'issued under [new, old] is signed with new');
    is_deeply([ verify(\%old, $S, $s2) ], [ undef, 'mac' ], '  and not with old');
}

# ---- the clearance ----------------------------------------------------------------

my $clr = $T->clear(\%cfg, $S, now => $NOW);
like($clr, qr/^v1\.\Q@{[ $NOW + 3600 ]}\E\.8\.[A-Za-z0-9_-]{22}\z/, 'a clearance has the wire shape');
my ($exp, $cbits, $cmac) = (split /\./, $clr)[1..3];

{
    my $msg = "clear\0$S\0$exp\0$cbits";
    my $want = Punk::Challenge::Token::_b64url(
        substr(Punk::Challenge::Token::_hmac_sha256('k', $msg), 0, 16));
    is($cmac, $want, 'the clearance MAC is the documented formula');
}

is_deeply([ cleared(\%cfg, $S, $clr) ], [ 8, 'ok' ], 'it clears');
is(scalar $T->cleared(\%cfg, $S, $clr, now => $NOW), 8, '  scalar context is the bits');
is_deeply([ cleared(\%cfg, $S, $clr, now => $NOW + 3599) ], [ 8, 'ok' ], '  up to a second before expiry');
is_deeply([ cleared(\%cfg, $S, $clr, now => $NOW + 3600) ], [ undef, 'expired' ], '  and not at it');
is_deeply([ cleared(\%cfg, $S, $clr, bits => 9) ], [ undef, 'bits' ],
    'a clearance below the demand is refused');
is_deeply([ cleared(\%cfg, $S, $clr, bits => 8) ], [ 8, 'ok' ], '  and at it accepted');
is_deeply([ cleared(\%cfg, '198.51.100.0/24', $clr) ], [ undef, 'mac' ],
    'from another subject it fails the MAC');

is_deeply([ cleared(\%cfg, $S, edited($clr, 1, $exp + 1)) ], [ undef, 'mac' ], 'exp moved fails the MAC');
is_deeply([ cleared(\%cfg, $S, edited($clr, 1, 'x')) ],      [ undef, 'shape' ], 'exp not decimal is not a clearance');
is_deeply([ cleared(\%cfg, $S, edited($clr, 2, 9), bits => 9) ], [ undef, 'mac' ],
    'bits raised in the cookie fails the MAC');
is_deeply([ cleared(\%cfg, $S, edited($clr, 2, 7)) ],  [ undef, 'mac' ], 'bits lowered fails the MAC');
is_deeply([ cleared(\%cfg, $S, edited($clr, 2, 0)) ],  [ undef, 'shape' ], 'bits 0 is not a clearance');
is_deeply([ cleared(\%cfg, $S, edited($clr, 2, 23)) ], [ undef, 'shape' ], 'bits 23 is not a clearance');
{
    my $flip = $cmac;
    substr($flip, 0, 1) = substr($flip, 0, 1) eq 'A' ? 'B' : 'A';
    is_deeply([ cleared(\%cfg, $S, edited($clr, 3, $flip)) ], [ undef, 'mac' ], 'a MAC character changed fails');
}
is_deeply([ cleared(\%cfg, $S, edited($clr, 3, substr($cmac, 0, 21))) ], [ undef, 'shape' ], 'a truncated MAC is not a clearance');
is_deeply([ cleared(\%cfg, $S, edited($clr, 3, '')) ], [ undef, 'shape' ], 'an empty MAC is not a clearance');
is_deeply([ cleared(\%cfg, $S, "$clr.1") ], [ undef, 'shape' ], 'an extra field is not a clearance');
is_deeply([ cleared(\%cfg, $S, '') ],      [ undef, 'shape' ], 'nothing is not a clearance');
is_deeply([ cleared(\%cfg, $S, undef) ],   [ undef, 'shape' ], 'undef is not a clearance');
is_deeply([ cleared(\%cfg, $S, $solution) ], [ undef, 'shape' ], 'a solution is not a clearance');

{
    my %old = (%cfg, secret => ['old']);
    my %both = (%cfg, secret => ['new', 'old']);
    my %new = (%cfg, secret => ['new']);
    my $c = $T->clear(\%old, $S, now => $NOW);
    is_deeply([ cleared(\%both, $S, $c) ], [ 8, 'ok' ], 'a clearance under old clears under [new, old]');
    is_deeply([ cleared(\%new, $S, $c) ],  [ undef, 'mac' ], '  and not under [new]');
}

# ---- domain separation --------------------------------------------------------------

{
    # the puzzle MAC over the clearance's fields, presented in the clearance slot
    my $msg = "puzzle\0$S\0$exp\0$cbits";
    my $wrong = Punk::Challenge::Token::_b64url(
        substr(Punk::Challenge::Token::_hmac_sha256('k', $msg), 0, 16));
    isnt($wrong, $cmac, 'the two domains give different MACs over the same fields');
    is_deeply([ cleared(\%cfg, $S, "v1.$exp.$cbits.$wrong") ], [ undef, 'mac' ],
        '  and the puzzle one is not a clearance');
}

done_testing;
