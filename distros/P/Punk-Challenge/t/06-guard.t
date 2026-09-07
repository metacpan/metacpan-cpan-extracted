#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use Punk::Plugin::Challenge ();

my $N = 0;

sub compile {
    my ($body) = @_;
    my $pkg = 'ChalGd' . ++$N;
    local $@;
    my $ok = eval "package $pkg;\nuse Punk;\n$body\n1";
    return ($pkg, $ok ? undef : $@);
}

my $PLUGIN = q{plugin 'Challenge' => { secret => 'k' };};
my $USE    = q{use Punk::Plugin::Challenge;};

sub bits_of { Punk::Plugin::Challenge::_guard_bits($_[0]) }

# ---- the factory ------------------------------------------------------------

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
$PLUGIN
our \$G = challenge_guard;
under '/register' => \$G;
PERL
    is($err, undef, 'the bareword form parses with the use') or diag $err;
    no strict 'refs';
    my $g = ${"${pkg}::G"};
    is(ref $g, 'CODE', '  and is a coderef');
    ok(!defined bits_of($g), '  with no difficulty of its own');
}

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
$PLUGIN
our \$G = challenge_guard(bits => 18);
under '/account' => \$G;
PERL
    is($err, undef, 'the parenthesised form parses') or diag $err;
    no strict 'refs';
    is(bits_of(${"${pkg}::G"}), 18, '  and captures its difficulty');
}

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
$PLUGIN
our \$G = challenge_guard({ bits => 20 });
PERL
    is($err, undef, 'the hashref form parses') or diag $err;
    no strict 'refs';
    is(bits_of(${"${pkg}::G"}), 20, '  and captures its difficulty');
}

{
    my ($pkg, $err) = compile(<<"PERL");
$PLUGIN
our \$G = challenge_guard(bits => 18);
PERL
    is($err, undef, 'the parenthesised form works without the use') or diag $err;
    no strict 'refs';
    is(bits_of(${"${pkg}::G"}), 18, '  because register installed it');
}

{
    my (undef, $err) = compile(<<"PERL");
$PLUGIN
under '/x' => challenge_guard;
PERL
    like($err, qr/challenge_guard/,
        'without the use, the bareword form is a compile error');
}

# ---- validated at the declaration -------------------------------------------

{
    my (undef, $err) = compile("$USE\n$PLUGIN\nchallenge_guard(bits => 23);");
    like($err, qr/`bits` must be between 1 and 22/, 'bits 23 croaks');
    (undef, $err) = compile("$USE\n$PLUGIN\nchallenge_guard(bits => 'x');");
    like($err, qr/`bits` must be a number/, 'bits x croaks');
    (undef, $err) = compile("$USE\n$PLUGIN\nchallenge_guard(bitz => 18);");
    like($err, qr/unknown challenge_guard option 'bitz' \(known: bits\)/,
        'an unknown option croaks naming what was available');
    (undef, $err) = compile("$USE\n$PLUGIN\nchallenge_guard('bits');");
    like($err, qr/takes key => value pairs or a hash reference/,
        'one bare string croaks');
}

# ---- the body needs the plugin ------------------------------------------------

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
our \$G = challenge_guard;
PERL
    is($err, undef, 'a guard can exist without the plugin line') or diag $err;
    no strict 'refs';
    my $g = ${"${pkg}::G"};
    local $@;
    eval { $g->(bless [], 'Punk::Context') };
    like($@, qr/needs the plugin \(add `plugin 'Challenge'/,
        '  and running it says what is missing');
}

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
our \$G = challenge_guard;
$PLUGIN
PERL
    no strict 'refs';
    my $g = ${"${pkg}::G"};
    local $@;
    eval { $g->(bless [], 'Punk::Context') };
    like($@, qr/Punk::Plugin::Challenge/,
        'a guard declared above the plugin line finds the plugin at the request');
    unlike($@, qr/needs the plugin/, '  and does not report it missing');
}

{
    my ($pkg, $err) = compile(<<"PERL");
$USE
$PLUGIN
our \$G = challenge_guard;
PERL
    no strict 'refs';
    my $g = ${"${pkg}::G"};
    my @r = $g->();
    is_deeply(\@r, [], 'a guard called with no context continues');
}

done_testing;
