#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use B ();
use Punk::View::Stencil;

# Punk::View::Stencil on Template::Stencil's C ABI (st_abi.h, vendored in
# include/punk/). The class is entirely XS and there is no Perl render path
# behind it, so what matters is that the boot-time gate is real and that the
# bytes are identical to what the engine's own render method produces -
# a view tier that quietly differed by which path served the request would be
# worse than one that failed loudly.

my $DIR = "$FindBin::Bin/test/MyApp/root/templates";

# ---- the class is XS ---------------------------------------------------------

for my $m (qw(new render opts engine)) {
    my $cv = Punk::View::Stencil->can($m);
    ok($cv, "Punk::View::Stencil->can('$m')");
    ok(B::svref_2object($cv)->XSUB, "...and $m is an XSUB");
}

is(Punk::View::Stencil::_abi_ok(), 1, 'the Stencil C ABI resolved');

# ---- construction ------------------------------------------------------------

my $v = Punk::View::Stencil->new({ template_dir => $DIR });
isa_ok($v, 'Punk::View::Stencil');
is(ref($v->engine), 'Template::Stencil', 'it holds a real engine object');
is($v->opts->{template_dir}, $DIR, 'the registered options are kept');
is(scalar @$v, 2, 'two slots, nothing else');

is(ref(Punk::View::Stencil->new(template_dir => $DIR)),
   'Punk::View::Stencil', 'the list constructor form works too');

# The engine is built at construction, not on first render, so a bad option
# fails with the rest of the configuration.
{
    my $err = '';
    eval { Punk::View::Stencil->new({ template_dir => '/no/such/dir' }) }
        or $err = $@;
    like($err, qr/not a directory/,
        'a bad option fails at construction, not on the first render');
}

# ---- rendering ---------------------------------------------------------------

is($v->render('{% a %}-{% b %}', { a => 1, b => 2 }), '1-2',
   'renders a source string');
is($v->render('{% v %}', { v => '<&>' }), '&lt;&amp;&gt;', 'auto-escapes');
is($v->render('no vars'), 'no vars', 'data is optional');

{   # wire-ready UTF-8 bytes, not a character string - the response body is
    # written to a socket, so this is the difference between correct output
    # and a wide-character warning
    my $out = $v->render('{% v %}', { v => "\x{2713}" });
    ok(!utf8::is_utf8($out), 'output is bytes, not characters');
    is(length $out, 3, 'the check mark is its three UTF-8 bytes');
}

# The opts hashref reaches the engine.
is($v->render('{% v %}', { v => 'w' }, { wrapper => undef }), 'w',
   'the third argument reaches the engine as render options');

# ---- identical to the engine's own render ------------------------------------

{
    my $raw = Template::Stencil->new(template_dir => $DIR);
    for my $case (
        [ '{% v %}',                              { v => 'plain' } ],
        [ '{% v %}',                              { v => "caf\x{e9} \x{2713}" } ],
        [ '{% for x in xs %}{% x %},{% end %}',   { xs => [ 1, 2, 3 ] } ],
        [ '{% if on %}y{% else %}n{% end %}',     { on => 1 } ],
    ) {
        my ($t, $d) = @$case;
        is($v->render($t, $d), $raw->render($t, $d),
           "byte-identical to Template::Stencil::render: $t");
    }
}

# ---- errors still croak ------------------------------------------------------
# The ABI hands template errors back as values; the adapter turns them into the
# exception the view tier already expects, so a broken template is a 500 rather
# than a silently empty page.

{
    my $err = '';
    eval { $v->render('{% nope(') } or $err = $@;
    like($err, qr/\S/, 'a malformed template croaks');
}
{
    my $err = '';
    eval { $v->render('x', 'not a hashref') } or $err = $@;
    like($err, qr/hashref/, 'non-hashref data croaks');
}
{
    my $err = '';
    eval { Punk::View::Stencil::render(bless([], 'Nope'), 'x') } or $err = $@;
    like($err, qr/not a view object|no engine/,
        'render on a foreign invocant croaks');
}

# ---- the version gate is real ------------------------------------------------
# There is no Perl fallback, so a missing or too-old Template::Stencil must be
# a boot error that names the version it needs. PUNK_FAKE_ST_BAD simulates the
# mismatch in a child, since the resolution is memoised per process.

SKIP: {
    require File::Temp;
    my ($fh, $script) = File::Temp::tempfile(UNLINK => 1, SUFFIX => '.pl');
    print $fh <<'CHILD';
use Punk::View::Stencil;
print Punk::View::Stencil::_abi_ok(), "|";
eval { Punk::View::Stencil->new({}) };
print $@;
CHILD
    close $fh;
    local $ENV{PUNK_FAKE_ST_BAD} = 1;
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $out = qx{"$^X" @inc "$script" 2>&1};
    skip 'could not run the guard child', 2 unless defined $out && length $out;
    like($out, qr/^0\|/, 'a version mismatch leaves the ABI unresolved');
    like($out, qr/ST_ABI_VERSION 1.*Template::Stencil to 0\.02/,
        'and construction croaks naming the version needed');
}

done_testing();
