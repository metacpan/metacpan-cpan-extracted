#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use Punk::Plugin::Challenge ();

my $N = 0;

# A whole Punk class from source, so the compile-time half of the keyword is
# exercised the way an application exercises it.
sub compile {
    my ($body) = @_;
    my $pkg = 'ChalKw' . ++$N;
    local $@;
    my $ok = eval "package $pkg;\nuse Punk;\n$body\n1";
    return $ok ? ($pkg->punk_app, undef) : (undef, $@);
}

my $PLUGIN = q{plugin 'Challenge' => { secret => 'k' };};
my $USE    = q{use Punk::Plugin::Challenge;};

sub rules { Punk::Plugin::Challenge::_rules($_[0]) }

# ---- the bareword form needs the use --------------------------------------

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge for => '/login', always => 1;
PERL
    is($err, undef, 'with the use, the bareword form parses') or diag $err;
    is_deeply(rules($app), [ {
        for => '/login', always => 1, limit => undef, window => undef,
        bits => undef, tag => '/login',
    } ], '  and records the rule with every key present');
}

{
    my ($app, $err) = compile(<<"PERL");
$PLUGIN
challenge for => '/login', always => 1;
PERL
    like($err, qr/\bchallenge\b/,
        'without the use, the bareword form is a compile error');
}

{
    my ($app, $err) = compile(<<"PERL");
$PLUGIN
challenge(for => '/login', always => 1);
PERL
    is($err, undef, 'the parenthesised form works without the use') or diag $err;
    is(scalar @{ rules($app) }, 1,
        '  because perl resolves it at runtime, when register has installed it');
}

# ---- a rule above the plugin line still records ---------------------------

{
    my ($app, $err) = compile(<<"PERL");
$USE
challenge for => '/login', always => 1;
$PLUGIN
PERL
    is($err, undef, 'a rule declared above the plugin line is accepted') or diag $err;
    is(scalar @{ rules($app) }, 1, '  and recorded');
}

# ---- every field ------------------------------------------------------------

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge for => '/api', after => { limit => 60, window => 60 }, bits => 18, tag => 'api';
PERL
    is($err, undef, 'an after rule with every field parses') or diag $err;
    is_deeply(rules($app), [ {
        for => '/api', always => 0, limit => 60, window => 60,
        bits => 18, tag => 'api',
    } ], '  and records each');
}

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge { for => '/api', always => 1 };
PERL
    is($err, undef, 'the hashref form parses') or diag $err;
    is(rules($app)->[0]{for}, '/api', '  and records the same rule');
}

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge always => 1;
PERL
    is($err, undef, 'for is optional') or diag $err;
    is(rules($app)->[0]{for}, '/', '  and defaults to the root');
    is(rules($app)->[0]{tag}, '/', '  as does the tag');
}

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge for => '/api/', always => 1;
PERL
    is($err, undef, 'a trailing slash is accepted') or diag $err;
    is(rules($app)->[0]{for}, '/api', '  and dropped');
    is(rules($app)->[0]{tag}, '/api', '  from the tag too');
}

# ---- layered rules keep their order -----------------------------------------

{
    my ($app, $err) = compile(<<"PERL");
$USE
$PLUGIN
challenge for => '/login', always => 1;
challenge for => '/', after => { limit => 60, window => 60 };
challenge for => '/login', always => 1, bits => 20;
PERL
    is($err, undef, 'three rules, two for one prefix, all parse') or diag $err;
    is_deeply([ map { [ $_->{for}, $_->{bits} ] } @{ rules($app) } ],
              [ [ '/login', undef ], [ '/', undef ], [ '/login', 20 ] ],
              '  and nothing merged or reordered them');
}

# ---- what croaks ------------------------------------------------------------

sub croaks_like {
    my ($body, $re, $name) = @_;
    my (undef, $err) = compile("$USE\n$PLUGIN\n$body");
    like($err, $re, $name);
}

croaks_like(q{challenge;},
    qr/needs `always => 1` or `after =>/, 'no arguments croaks');
croaks_like(q{challenge for => '/x';},
    qr/needs `always => 1` or `after =>/, 'neither always nor after croaks');
croaks_like(q{challenge for => '/x', always => 0;},
    qr/needs `always => 1` or `after =>/, 'always => 0 is neither');
croaks_like(q{challenge for => '/x', always => 1, after => { limit => 1, window => 1 };},
    qr/has `always` or `after`, not both/, 'both croaks');
croaks_like(q{challenge for => '/x', after => 60;},
    qr/`after` must be \{ limit => N, window => S \}/, 'after as a number croaks');
croaks_like(q{challenge for => '/x', after => { window => 60 };},
    qr/`after` needs `limit`/, 'after without limit croaks');
croaks_like(q{challenge for => '/x', after => { limit => 60 };},
    qr/`after` needs `window`/, 'after without window croaks');
croaks_like(q{challenge for => '/x', after => { limit => 0, window => 60 };},
    qr/`limit` must be between/, 'limit 0 croaks');
croaks_like(q{challenge for => '/x', after => { limit => 6, window => 'x' };},
    qr/`window` must be a number/, 'window x croaks');
croaks_like(q{challenge for => '/x', after => { limit => 6, window => 6, burst => 1 };},
    qr/unknown after option 'burst' \(known: limit, window\)/,
    'an unknown after option croaks naming what was available');
croaks_like(q{challenge for => '/x', always => 1, bitz => 20;},
    qr/unknown challenge option 'bitz' \(known: for, always, after, bits, tag\)/,
    'an unknown option croaks naming what was available');
croaks_like(q{challenge for => '/x', always => 1, bits => 23;},
    qr/`bits` must be between 1 and 22/, 'bits 23 croaks');
croaks_like(q{challenge for => '/x', always => 1, bits => 0;},
    qr/`bits` must be between 1 and 22/, 'bits 0 croaks');
croaks_like(q{challenge for => 'x', always => 1;},
    qr/`for` must be a rooted path, not 'x'/, 'an unrooted prefix croaks');
croaks_like(q{challenge for => '/x?y', always => 1;},
    qr/`for` must be a rooted path/, 'a query in the prefix croaks');
croaks_like(q{challenge for => '/x', always => 1, tag => '';},
    qr/`tag` must not be empty/, 'an empty tag croaks');
croaks_like(q{challenge for => '/x', always => 1, tag => 'a b';},
    qr/`tag` must be a plain word/, 'a tag with a space croaks');
croaks_like(q{challenge for => '/x', always => 1, tag => 'a:b';},
    qr/`tag` must be a plain word/, 'a tag with a colon croaks');
croaks_like(q{challenge 'for';},
    qr/takes key => value pairs or a hash reference/, 'one bare string croaks');
croaks_like(q{challenge for => '/x', 'always';},
    qr/odd number of arguments/, 'an odd list croaks');

done_testing;
