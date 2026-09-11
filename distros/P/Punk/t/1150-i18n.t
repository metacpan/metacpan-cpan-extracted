#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Punk ();

# Punk::Plugin::I18n - the catalogue, and the lookup over it.
#
# The catalogue is read once at boot into a C arena rather than into Perl
# data, and that is not a micro-optimisation: loading before the fork is only
# worth doing if the pages STAY shared, and the first read of an SV touches
# its refcount and copies the page.

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub write_cat {
    my ($tag, $json) = @_;
    my $path = File::Spec->catfile($dir, "$tag.json");
    open my $fh, '>:raw', $path or die $!;
    print $fh $json;
    close $fh;
    return $path;
}

write_cat('en', <<'JSON');
{
  "greeting": "Hello, {name}",
  "welcome":  "Welcome to <a href=\"/\">the site</a>",
  "bare":     "no placeholders here",
  "items":    { "one": "1 item", "other": "{count} items" },
  "only_en":  "present in English alone"
}
JSON
write_cat('en-GB', '{ "greeting": "Hullo, {name}" }');
write_cat('fr',    '{ "greeting": "Bonjour, {name}" }');

sub app_with {
    my (%opts) = @_;
    my $n = ++our $N;
    my $pkg = "I18nApp$n";
    my $code = qq{
        package $pkg;
        use Punk;
        plugin 'I18n' => { dir => '$opts{dir}', default => '$opts{default}' };
        get '/g' => sub { \$_[0]->text(\$_[0]->locale('greeting', name => 'Bob')) };
        get '/tag' => sub { \$_[0]->text(\$_[0]->locale) };
        1;
    };
    eval $code or die $@;
    return $pkg;
}

sub env_for {
    my (%o) = @_;
    return {
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $o{path} || '/g',
        QUERY_STRING   => $o{query} || '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        ($o{lang}   ? (HTTP_ACCEPT_LANGUAGE => $o{lang})   : ()),
        ($o{cookie} ? (HTTP_COOKIE          => $o{cookie}) : ()),
    };
}

my $pkg = app_with(dir => $dir, default => 'en');
my $app = $pkg->to_app;
sub body { my $r = $app->(env_for(@_)); return $r->[2][0] }

# ---- the lookup --------------------------------------------------------------
{
    is(body(lang => 'fr'), 'Bonjour, Bob', 'the negotiated catalogue answers');
    is(body(lang => 'en'), 'Hello, Bob',   'and so does another one');
    is(body(),             'Hello, Bob',
        'with no Accept-Language at all, the default does');
}

# ---- the tag itself ----------------------------------------------------------
{
    is(body(path => '/tag', lang => 'fr'), 'fr',
        '$c->locale with no arguments is the negotiated tag - a template '
      . 'needs it for <html lang=> and a switcher for its current state');
    is(body(path => '/tag', lang => 'en-GB'), 'en-gb',
        'folded, because language tags are case insensitive');
}

# ---- interpolation -----------------------------------------------------------
{
    my $c = Punk::Plugin::I18n->_interpolate('Hello, {name}', name => 'Bob');
    is($c, 'Hello, Bob', 'a placeholder is substituted');

    is(Punk::Plugin::I18n->_interpolate('{a} and {b}', a => 1, b => 2),
        '1 and 2', 'more than one');

    is(Punk::Plugin::I18n->_interpolate('Hello, {nmae}', name => 'Bob'),
        'Hello, {nmae}',
        'an UNKNOWN placeholder is left literal - visibly wrong in the page, '
      . 'rather than a gap nobody notices');

    is(Punk::Plugin::I18n->_interpolate('Hello, {name}'),
        'Hello, {name}',
        'and a missing substitution does not take the page down: a '
      . 'translator may add a placeholder before a caller passes it');

    is(Punk::Plugin::I18n->_interpolate('Hi {name}', name => undef),
        'Hi ', 'an explicit undef renders as nothing');

    is(Punk::Plugin::I18n->_interpolate('a { b } c', ' b ' => 'X'),
        'a X c', 'the name is whatever is between the braces');

    is(Punk::Plugin::I18n->_interpolate('50% { of 100', x => 1),
        '50% { of 100', 'an unclosed brace is left alone');

    # The one that matters: a value is not a template.
    is(Punk::Plugin::I18n->_interpolate('Hello, {name}', name => '{greeting}'),
        'Hello, {greeting}',
        'a substituted value is NOT rescanned - a user named {greeting} '
      . 'cannot reach into the catalogue');
}

# ---- a missing key returns the KEY -------------------------------------------
{
    my $p = app_with(dir => $dir, default => 'en');
    eval qq{
        package $p;
        get '/missing' => sub { \$_[0]->text(\$_[0]->locale('no.such.key')) };
        1;
    } or die $@;
    my $a = $p->to_app;
    my $r = $a->(env_for(path => '/missing'));
    is($r->[2][0], 'no.such.key',
        'a missing key renders as the key - an empty string hides the '
      . 'omission until a user finds it, while the key is visible in the '
      . 'page and greppable in the logs');

    my %s = Punk::Plugin::I18n->stats;
    cmp_ok($s{missing}, '>=', 1,
        'and it is counted, because a page nobody reported is still wrong');
}

# ---- falling back to the default catalogue -----------------------------------
{
    my $p = app_with(dir => $dir, default => 'en');
    eval qq{
        package $p;
        get '/only' => sub { \$_[0]->text(\$_[0]->locale('only_en')) };
        1;
    } or die $@;
    my $a = $p->to_app;
    my $r = $a->(env_for(path => '/only', lang => 'fr'));
    is($r->[2][0], 'present in English alone',
        'a key missing from the negotiated catalogue falls back to the '
      . 'default - that fallback is what a partly translated site IS');
}

# ---- nested keys join with a dot ---------------------------------------------
{
    my $p = app_with(dir => $dir, default => 'en');
    eval qq{
        package $p;
        get '/n' => sub { \$_[0]->text(\$_[0]->locale('items.other', count => 3)) };
        1;
    } or die $@;
    my $a = $p->to_app;
    is($a->(env_for(path => '/n'))->[2][0], '3 items',
        'a nested object is reachable as items.other, which is what a '
      . 'translator writing either form expects it to mean');
}

# ---- markup in a catalogue entry survives ------------------------------------
{
    my $p = app_with(dir => $dir, default => 'en');
    eval qq{
        package $p;
        get '/w' => sub { \$_[0]->text(\$_[0]->locale('welcome')) };
        1;
    } or die $@;
    my $a = $p->to_app;
    like($a->(env_for(path => '/w'))->[2][0], qr{<a href="/">},
        'a catalogue entry carrying markup comes back with it - the '
      . 'catalogue is the trusted half, and a link inside a sentence is the '
      . 'ordinary case');
}

# ---- boot errors -------------------------------------------------------------
# Every one of these is a deploy-time failure in front of whoever deployed it,
# rather than a missing string at three in the morning.
{
    my $bad = File::Temp::tempdir(CLEANUP => 1);
    write_cat_in($bad, 'en', '{ "a": "b" ');
    my $err = boot_err($bad, 'en');
    like($err, qr/\Qwill not parse\E/, 'a malformed catalogue fails at boot');
    like($err, qr/\Qen.json\E/,
        'and the message names the FILE - "malformed JSON at offset 412" '
      . 'names neither the file nor the locale, and there is one per language');

    my $empty = File::Temp::tempdir(CLEANUP => 1);
    like(boot_err($empty, 'en'), qr/no \*\.json catalogues/,
        'an empty directory is a typo in `dir`, not a working default');

    like(boot_err(File::Spec->catdir($dir, 'nope'), 'en'),
        qr/does not exist/, 'and a missing directory says so');

    like(boot_err($dir, 'de'), qr/\Qdefault locale 'de'\E/,
        'a default with no catalogue fails at boot - it is the answer when '
      . 'negotiation finds nothing, so it is the one locale that must exist');

    my $notobj = File::Temp::tempdir(CLEANUP => 1);
    write_cat_in($notobj, 'en', '["a","b"]');
    like(boot_err($notobj, 'en'), qr/not a JSON object/,
        'a catalogue that is not a map of key to translation says so');
}

sub write_cat_in {
    my ($d, $tag, $json) = @_;
    open my $fh, '>:raw', File::Spec->catfile($d, "$tag.json") or die $!;
    print $fh $json;
    close $fh;
}

sub boot_err {
    my ($d, $default) = @_;
    my $n = ++our $E;
    my $code = qq{
        package I18nBoot$n;
        use Punk;
        plugin 'I18n' => { dir => '$d', default => '$default' };
        1;
    };
    eval $code;
    return $@ || '';
}

# ---- a missing key WARNS, in development, ONCE ------------------------------
# Twenty renders of the same page must produce one line. Noise is ignored, and
# being ignored is how the omission survives to reach a user.
SKIP: {
    skip 'the warning is development-only and PUNK_ENV is set otherwise', 5
        if ($ENV{PUNK_ENV} || '') ne '' && ($ENV{PUNK_ENV} ne 'development');

    local $ENV{PUNK_ENV} = 'development';
    our @LOG;

    eval qq{
        package I18nDev;
        use Punk;
        plugin 'I18n' => { dir => '$dir', default => 'en' };
        logging to => sub { push \@main::LOG, \$_[0] };
        get '/m' => sub { \$_[0]->text(\$_[0]->locale('absent.key')) };
        get '/n' => sub { \$_[0]->text(\$_[0]->locale('other.absent')) };
        1;
    } or die $@;

    my $a = I18nDev->to_app;
    Punk::Plugin::I18n->_reset;
    @LOG = ();

    my $r = $a->(env_for(path => '/m'));
    is($r->[2][0], 'absent.key', 'the key still renders as the key');

    $a->(env_for(path => '/m')) for 2 .. 20;
    my @hits = grep { /absent\.key/ } @LOG;
    is(scalar @hits, 1,
        'twenty renders of a missing key warn ONCE - the same page warning '
      . 'every request is noise, and noise is filtered out');
    like($hits[0], qr/absent\.key/, 'and the warning names the key');

    $a->(env_for(path => '/n'));
    is(scalar(grep { /other\.absent/ } @LOG), 1,
        'a DIFFERENT missing key warns on its own - once per key, not once '
      . 'per process');

    my %s = Punk::Plugin::I18n->stats;
    is($s{warned}, 2, 'and the warnings are counted');
}

# ---- and never in production -------------------------------------------------
# Asserted on the COUNTER, not on the absence of a log line: "no warning
# appeared" also passes when the warning is broken.
{
    local $ENV{PUNK_ENV} = 'production';
    our @PLOG;

    eval qq{
        package I18nProd;
        use Punk;
        plugin 'I18n' => { dir => '$dir', default => 'en' };
        logging to => sub { push \@main::PLOG, \$_[0] };
        get '/m' => sub { \$_[0]->text(\$_[0]->locale('absent.key')) };
        1;
    } or die $@;

    my $a = I18nProd->to_app;
    Punk::Plugin::I18n->_reset;
    @PLOG = ();

    $a->(env_for(path => '/m')) for 1 .. 20;

    my %s = Punk::Plugin::I18n->stats;
    is($s{warned}, 0,
        'in production the warning never fires - a missing key is ALREADY '
      . 'visible in the page, so a line per request tells somebody something '
      . 'they can see and cannot act on');
    is($s{missing}, 20, '...while the counter still counts every one of them');
    is(scalar(grep { /absent\.key/ } @PLOG), 0, 'and nothing reached the log');
}

# ---- untranslated is NOT missing ---------------------------------------------
# One is a bug, the other is a translation nobody has written yet, and an
# application that cannot tell them apart cannot measure its own coverage.
{
    my $chain = File::Temp::tempdir(CLEANUP => 1);
    write_cat_in($chain, 'en', '{ "a": "A", "b": "B" }');
    write_cat_in($chain, 'fr', '{ "a": "Aaa" }');

    eval qq{
        package I18nCover;
        use Punk;
        plugin 'I18n' => { dir => '$chain', default => 'en' };
        get '/a' => sub { \$_[0]->text(\$_[0]->locale('a')) };
        get '/b' => sub { \$_[0]->text(\$_[0]->locale('b')) };
        get '/z' => sub { \$_[0]->text(\$_[0]->locale('z')) };
        1;
    } or die $@;
    my $a = I18nCover->to_app;

    Punk::Plugin::I18n->_reset;
    is($a->(env_for(path => '/a', lang => 'fr'))->[2][0], 'Aaa',
        'a translated key comes from the negotiated catalogue');
    my %s = Punk::Plugin::I18n->stats;
    is($s{untranslated}, 0, 'and nothing is counted as untranslated');

    Punk::Plugin::I18n->_reset;
    is($a->(env_for(path => '/b', lang => 'fr'))->[2][0], 'B',
        'a key missing from fr but present in en falls back');
    %s = Punk::Plugin::I18n->stats;
    is($s{untranslated}, 1, '...and is counted as UNTRANSLATED');
    is($s{missing}, 0, 'not as missing, because it is not a bug');

    Punk::Plugin::I18n->_reset;
    is($a->(env_for(path => '/z', lang => 'fr'))->[2][0], 'z',
        'a key in NO catalogue renders as the key');
    %s = Punk::Plugin::I18n->stats;
    is($s{missing}, 1, '...and that one IS counted as missing');
    is($s{untranslated}, 0, 'and not as untranslated');
}

# ---- a dotted key is refused at boot ------------------------------------------
#
# It used to be indistinguishable from the nested form, and worse than
# ambiguously: the old arena flattened {"a": {"b": x}} to the string "a.b",
# a literal key "a.b" produced the same string, and which of the two won was
# decided by Perl's hash order - which is perturbed per process. Two workers
# in one pool could serve different translations for the same key, so a page
# changed wording on refresh.
#
# The block holds a tree, so the nested form is a real path. That leaves the
# literal "a.b" key unreachable - $c->locale descends past it, and a
# template splits on dots before the lookup ever runs - so it is refused at
# boot rather than left to be a silent miss.
{
    my $d = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>:raw', File::Spec->catfile($d, 'en.json') or die $!;
    print $fh '{"a.b":"FLAT","a":{"b":"NESTED"}}';
    close $fh;

    my $err = boot_err($d, 'en');
    like($err, qr/\Qkey containing a dot\E/,
        'a literal dotted key is a boot error, not a silent miss');
    like($err, qr/\Qa.b\E/, 'and the message names the key');

    # The same catalogue without the collision resolves, so the refusal is
    # narrow: it is the dot in a KEY that is refused, not nesting.
    my $d2 = File::Temp::tempdir(CLEANUP => 1);
    open my $fh2, '>:raw', File::Spec->catfile($d2, 'en.json') or die $!;
    print $fh2 '{"a":{"b":"NESTED"}}';
    close $fh2;

    my $pkg = 'I18nDot';
    eval qq{
        package $pkg;
        use Punk;
        plugin 'I18n' => { dir => '$d2', default => 'en' };
        get '/ab' => sub { \$_[0]->text(\$_[0]->locale('a.b')) };
        1;
    } or die $@;
    is($pkg->to_app->(env_for(path => '/ab'))->[2][0], 'NESTED',
        'and the nested form still answers a dotted lookup');
}

# ---- a translation is text; what cannot become text is refused at boot --------
#
# The old arena called SvPV on every value, so a JSON number was simply its
# digits and {"count": 5} worked. The block records the KIND, so an untouched
# 5 freezes as an integer and the lookup - which returns text - has nothing
# to give back. That would have been a SILENT miss rendering as the key.
#
# Numbers are therefore stringified at load, which is what the old arena did
# implicitly. What has no sensible text form - an array, null, a boolean -
# is refused at boot with the path named, where before it was silent or,
# for null, quietly an empty string.
{
    my $boot = sub {
        my ($json) = @_;
        my $d = File::Temp::tempdir(CLEANUP => 1);
        open my $fh, '>:raw', File::Spec->catfile($d, 'en.json') or die $!;
        print $fh $json;
        close $fh;
        return ($d, boot_err($d, 'en'));
    };
    my $refuse = sub { (my $d, my $e) = $boot->(@_); return $e };

    like($refuse->('{"nope":null}'), qr/\Qnull at 'nope'\E/,
        'null is refused, naming the path');
    like($refuse->('{"list":["a","b"]}'), qr/\Qan array at 'list'\E/,
        'an array is refused - fz_path descends through objects, so nothing '
      . 'in the surface could ever have reached its elements');
    like($refuse->('{"on":true}'), qr/\Qblessed reference\E/,
        'a boolean is refused by the freeze itself, which names the path');
    like($refuse->('{"a":{"b":{"c":null}}}'), qr/\Qat 'a.b.c'\E/,
        'and the path is the joined one, however deep');

    # Numbers go through, as text, exactly as they did in 0.48.
    my ($d) = $boot->('{"count":5,"pi":1.5,"s":"x"}');
    my $pkg = 'I18nNum';
    eval qq{
        package $pkg;
        use Punk;
        plugin 'I18n' => { dir => '$d', default => 'en' };
        get '/k' => sub { \$_[0]->text(\$_[0]->locale(\$_[0]->param('k'))) };
        1;
    } or die $@;
    my $app = $pkg->to_app;
    my $at = sub { $app->(env_for(path => '/k', query => 'k=' . $_[0]))->[2][0] };

    is($at->('count'), '5',   'an integer reads back as its digits');
    is($at->('pi'),    '1.5', 'and so does a fractional number');
    is($at->('s'),     'x',   'beside an ordinary string');
}

# ---- a key resolves at every depth, through the fast door ---------------------
#
# The lookup became a segment WALK: one probe per dot where the joined key
# was one probe whatever its depth. So depth is now a thing that can break,
# and nothing pinned it on the $c->locale side - t/1152 covers the template
# door only.
#
# The cost is real and measured: 40 keys of mixed depth are 81 probes here
# where they were 40. See plan_punk_frozen/03-catalogue-block.md.
{
    my $d = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>:raw', File::Spec->catfile($d, 'en.json') or die $!;
    print $fh '{"one":"1","two":{"x":"2"},"three":{"x":{"y":"3"}},'
            . '"four":{"a":{"b":{"c":"4"}}},"empty":{"s":""}}';
    close $fh;

    my $pkg = 'I18nDepth';
    eval qq{
        package $pkg;
        use Punk;
        plugin 'I18n' => { dir => '$d', default => 'en' };
        get '/k' => sub { \$_[0]->text(\$_[0]->locale(\$_[0]->param('k'))) };
        1;
    } or die $@;
    my $app = $pkg->to_app;
    my $at  = sub {
        $app->(env_for(path => '/k', query => 'k=' . $_[0]))->[2][0];
    };

    is($at->('one'),          '1', 'one segment resolves');
    is($at->('two.x'),        '2', 'two segments resolve');
    is($at->('three.x.y'),    '3', 'three segments resolve');
    is($at->('four.a.b.c'),   '4', 'four segments resolve');

    # A level is not a leaf. Asking for one as a string gets the key back,
    # the same answer a miss gets, because there is no translation AT
    # `three` - only below it.
    is($at->('three'),   'three',   'a branch asked for as a string is not a hit');
    is($at->('three.x'), 'three.x', 'nor is an intermediate branch');

    # An empty translation is a HIT with nothing in it, not a miss. The old
    # arena needed a sentinel to tell those apart; a leaf and a level are
    # now different node kinds, so the distinction is structural.
    is($at->('empty.s'), '', 'an empty string is a hit, not a miss');

    is($at->('two.nope'), 'two.nope', 'a missing leaf under a real branch misses');
    is($at->('nope.x'),   'nope.x',   'and so does a path through a missing branch');
}

# ---- a failed boot does not leak the block ------------------------------------
#
# The validation walk records a fault and lets the CALLER croak. That is not
# style: Frozen's own fz_walk mallocs a segment stack and frees it after the
# walk returns, so a croak from inside longjmps past that free and leaks on
# every boot - and `punk dev` reboots the app on every file change, so it
# would be a slow leak with no visible cause.
#
# Measured as a DIFFERENCE against a boot that fails before any block is
# built. An absolute RSS bound would be measuring Perl's per-package
# overhead, which is most of the growth here and is never reclaimed.
SKIP: {
    my $rss = sub { my $k = `ps -o rss= -p $$` || ''; $k =~ /(\d+)/ ? $1 : 0 };
    skip 'ps -o rss is not usable here', 1 unless $rss->() > 0;

    my $body = '{' . join(',', map { qq{"k$_":"v$_ padding padding padding"} }
                                1 .. 500);
    my %d;
    for my $case (qw(early late)) {
        $d{$case} = File::Temp::tempdir(CLEANUP => 1);
        open my $fh, '>:raw', File::Spec->catfile($d{$case}, 'en.json') or die $!;
        print $fh $case eq 'late' ? "$body,\"bad\":null}" : "$body}";
        close $fh;
    }

    my $n = 0;
    my $boot = sub {
        my ($case) = @_;
        my $pkg = 'I18nLeak' . ++$n;
        my $dir = $case eq 'early' ? '/no/such/directory/anywhere' : $d{$case};
        eval qq{
            package $pkg;
            use Punk;
            plugin 'I18n' => { dir => '$dir', default => 'en' };
            1;
        };
    };

    my %grew;
    for my $case (qw(early late)) {
        $boot->($case) for 1 .. 10;          # warm the allocator
        my $before = $rss->();
        $boot->($case) for 1 .. 100;
        $grew{$case} = $rss->() - $before;
    }
    my $extra = $grew{late} - $grew{early};
    note sprintf 'growth over 100 boots: before-the-block %d KB, '
               . 'after-it-is-built %d KB, difference %d KB',
               $grew{early}, $grew{late}, $extra;

    # A leaked block would be ~25 KB x 100. The observed difference is
    # tens of KB, so this bound is loose by two orders of magnitude and
    # still catches the failure it exists for.
    cmp_ok($extra, '<', 2048,
        'failing validation after the block is built leaks no more than '
      . 'failing before it exists');
}

done_testing;
