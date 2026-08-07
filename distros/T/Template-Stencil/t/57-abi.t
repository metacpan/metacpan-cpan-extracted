#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Template::Stencil;

# The shared C ABI (include/st_abi.h). _abi_selftest drives the table the way
# a consumer does - resolve through Template::Stencil::_abi_ptr, gate on
# abi_version, then engine_of -> render through the function pointers - so
# what these assert is the contract a consumer compiles against, not the
# internal C the render method happens to reach.

my $dir = File::Temp::tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/page.tmpl" or die $!;
print $fh '<p>{% name %}</p>';
close $fh;
open $fh, '>', "$dir/wrap.tmpl" or die $!;
print $fh '[{% content %}]';
close $fh;

# ---- the table itself --------------------------------------------------------

my $ptr = Template::Stencil::_abi_ptr();
ok($ptr, '_abi_ptr returns an address');
is(Template::Stencil::_abi_ptr(), $ptr, 'the table is static - same address');

# ---- engine_of ---------------------------------------------------------------

my $s = Template::Stencil->new(template_dir => $dir);

# An engine that has never rendered still resolves: engine_of builds it
# lazily, exactly as the render method would.
is(Template::Stencil::_abi_selftest($s, '{% v %}', { v => 'lazy' }), 'lazy',
   'engine_of builds the engine on first use');

for my $bad ([], 'Template::Stencil', bless({}, 'Not::Stencil'), undef, 42) {
    my @r = Template::Stencil::_abi_selftest($bad, '{% v %}', { v => 1 });
    is(scalar @r, 0, 'engine_of returns NULL for '
        . (defined $bad ? (ref($bad) || "'$bad'") : 'undef'));
}

# ---- render ------------------------------------------------------------------

is(Template::Stencil::_abi_selftest($s, 'page', { name => 'abi' }),
   '<p>abi</p>', 'renders a named template through the table');
is(Template::Stencil::_abi_selftest($s, '{% a %}-{% b %}', { a => 1, b => 2 }),
   '1-2', 'renders a source string through the table');
is(Template::Stencil::_abi_selftest($s, 'page', { name => '<&>' }),
   '<p>&lt;&amp;&gt;</p>', 'auto-escaping applies');

# data may be absent entirely - the ABI substitutes an empty hash rather
# than making every caller allocate one.
is(Template::Stencil::_abi_selftest($s, 'no vars here'), 'no vars here',
   'a NULL data hash renders');

# opts ride through: the wrapper override is the one a view tier needs.
is(Template::Stencil::_abi_selftest($s, 'page', { name => 'w' },
        { wrapper => 'wrap' }),
   '[<p>w</p>]', 'the opts hashref reaches the engine (wrapper override)');

{   # an engine with a default wrapper, overridden back off
    my $w = Template::Stencil->new(template_dir => $dir, wrapper => 'wrap');
    is(Template::Stencil::_abi_selftest($w, 'page', { name => 'd' }),
       '[<p>d</p>]', 'the engine default wrapper applies');
    is(Template::Stencil::_abi_selftest($w, 'page', { name => 'd' },
            { wrapper => undef }),
       '<p>d</p>', 'wrapper => undef turns it off');
}

# ---- errors come back, they do not croak -------------------------------------
# The whole point for a consumer: a bad template is a value it can turn into
# its own 500, not an exception it has to eval around.

{
    my @r = eval { Template::Stencil::_abi_selftest($s, '{% nope(') };
    ok(!$@, 'a malformed template does not croak through the ABI')
        or diag $@;
    is(scalar @r, 2, 'it returns the failure pair');
    ok(!defined $r[0], 'no output on failure');
    like($r[1], qr/\S/, 'an error message comes back');
}

{   # strict => 1 turns an undef value into a render-time error
    my $strict = Template::Stencil->new(template_dir => $dir, strict => 1);
    my @r = eval { Template::Stencil::_abi_selftest($strict, '{% missing %}') };
    ok(!$@, 'a render-time error does not croak through the ABI') or diag $@;
    is(scalar @r, 2, 'it returns the failure pair');
    like($r[1], qr/\S/, 'the render error comes back as a value');
}

# The documented name-vs-source rule holds on this path too: a name that
# resolves to no file is source, not an error.
is(Template::Stencil::_abi_selftest($s, 'no-such-template'),
   'no-such-template', 'an unresolvable name falls through to source');

# ---- the bytes match the Perl-visible render ---------------------------------
# A consumer must get exactly what the method gives, including the UTF-8
# wire-bytes default, or output differs by which path served the request.

for my $case (
    [ 'page',                 { name => 'plain' } ],
    [ '{% v %}',              { v => "caf\x{e9} \x{2713}" } ],
    [ '{% for x in xs %}{% x %},{% end %}', { xs => [ 1, 2, 3 ] } ],
) {
    my ($tmpl, $data) = @$case;
    my $via_abi    = Template::Stencil::_abi_selftest($s, $tmpl, $data);
    my $via_method = $s->render($tmpl, $data);
    is($via_abi, $via_method, "ABI and method agree: $tmpl");
    is(utf8::is_utf8($via_abi), utf8::is_utf8($via_method),
       "...and agree on the UTF-8 flag: $tmpl");
}

{   # chars => 1 must reach the ABI path too
    my $c = Template::Stencil->new(template_dir => $dir, chars => 1);
    my $out = Template::Stencil::_abi_selftest($c, '{% v %}',
        { v => "\x{2713}" });
    ok(utf8::is_utf8($out), 'chars => 1 yields a character string');
    is($out, $c->render('{% v %}', { v => "\x{2713}" }),
       'and matches the method');
}

# ---- the caller owns the returned SV -----------------------------------------
# Rendering in a loop must not leak or hand back a shared buffer.

{
    my @out = map { Template::Stencil::_abi_selftest($s, 'page', { name => $_ }) }
              1 .. 50;
    is(scalar(grep { $out[$_] eq '<p>' . ($_ + 1) . '</p>' } 0 .. 49), 50,
       'each render returns its own buffer');
}

done_testing();
