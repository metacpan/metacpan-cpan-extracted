#!/usr/bin/perl

use Test::More tests => 25;

BEGIN { use_ok( 'Regexp::Genex' ); }

use Regexp::Genex qw(:all);

# not tested:
# length
# MAX_QUANTIFIERS

# perl -MGx -le 'print for strings($ARGV[0])' 

# strings
is_deeply([strings('a')],['a']);
is_deeply([strings(qr'a')],['a']);
is_deeply([strings('\141')],["\141"]);
is_deeply([strings('\n')],["\n"]);
is_deeply([strings('\x62')],["\x62"]);
is_deeply([strings('a|b')],[qw(a b)]);
is_deeply([strings('ab?')],[qw(ab a)]);
is_deeply([strings('ab??')],[qw(a ab)]);
is_deeply([strings('ab{2,4}?')],[qw(abb abbb abbbb)]);
#is_deeply([strings('a(bb)??')],[qw(a abb)], 'patched YAPE::Regex required');

ok(!grep {!/^[ab]$/} strings('[ab]'));
ok(!grep {!/^a*b+$/} strings('a*b+'));
# backref
ok(!grep {!/^(aa|bb)$/} strings('([ab])\1'));

# case lumpiness
for (1..20) { $got{ (strings(qr/aBc/i))[0] } = 1 };
ok( (keys %got) > 1, 'May fail by pure bad luck, rerun');
# diag(keys %got);

# strings_rx
my $rx = strings_rx(qr/\\{}}\$\n /);
ok($rx =~ /Orignal/);
use re 'eval';
('a'x10) =~ qr/$rx/x;
is $_[0], "\\{}}\$\n ";

my $gen = generator(qr/ab*?/);

is($gen->(),'a');
is($gen->(),'ab');
is($gen->(),'abb');
is($gen->(0),'a');
is($gen->(),'ab');

ok(generator_rx(qr/ab*?/));

{
    # [rt.cpan.org #23762] Wrong strings() output for long (?) regexpes
    is_deeply([strings('123456789[i]')],['123456789i']);

    # just over the default output length
    local $Regexp::Genex::DEFAULT_LEN = 10;
    is_deeply([strings('1234567890[i]')],['1234567890[i]']);

    # increase the limit
    local $Regexp::Genex::DEFAULT_LEN = 20;
    is_deeply([strings('1234567890[i]')],['1234567890i']);
}
