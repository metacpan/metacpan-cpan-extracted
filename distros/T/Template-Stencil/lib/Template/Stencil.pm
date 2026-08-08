package Template::Stencil;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Template::Stencil', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Template::Stencil - a fast template engine

=head1 SYNOPSIS

    use Template::Stencil;

    my $stencil = Template::Stencil->new(
        template_dir => 'templates',
        wrapper      => 'wrapper.tmpl',
    );

    my $html = $stencil->render('index', {
        title => 'Hello',
        items => [ { name => 'one' }, { name => 'two' } ],
    });

    # index.tmpl
    # <h1>{% title | upper %}</h1>
    # <ul>
    # {% for item in items %}<li>{% item.name %}</li>
    # {% end %}
    # </ul>

=head1 DESCRIPTION

Template::Stencil compiles a small C<{% %}> template grammar once into
packed bytecode held in a single memory arena, then renders it with a
threaded C interpreter that writes straight into an SV-backed buffer.
The returned scalar is that buffer.

Design points:

=over 4

=item * Compile once, render from cache forever. File templates are
cached with mtime revalidation; string templates are cached by content
hash in a bounded LRU.

=item * Zero per-render heap allocation and zero per-render system
calls at steady state (hash-key iteration is the one documented
exception - one small vector per hash loop).

=item * One engine per process/worker; nothing is shared, so nothing
is locked. Construct after fork (or just construct lazily - a
thread-cloned object rebuilds its own engine automatically).

=back

=head1 TEMPLATE SYNTAX

Everything uses one delimiter pair, C<{% %}>, and every block closes
with C<{% end %}>. Whitespace inside the delimiters is insignificant:
C<{%name%}> and C<{% name %}> are identical.

=head2 Output tags

    {% name %}              variable, HTML-escaped
    {% page.header %}       dotted path through hashrefs
    {% page.number[0] %}    array index; mixes freely: a.b[0][1].c
    {% raw name %}          same resolution, no escaping
    {% name | upper %}      filters (see below)

Auto-escaping replaces C<< < > & " ' >> with entities. C<raw> is the
opt-out. An undefined or missing path renders as the empty string
(croaks under C<strict>). Paths resolve innermost-scope-first: loop
variables and C<set> bindings shadow outer scopes; the data hashref
passed to C<render> is the outermost scope. Paths may be up to 8
segments deep; traversing through a blessed reference is an error.

=head2 Filters

    {% name | upper %}
    {% price | default('0.00') %}
    {% summary | trim | lower %}

Filters chain left to right. Auto-escaping happens once, after the
last filter, unless the tag is C<raw> or the chain ends in C<html>
(never double-escaped; a filter running after C<html> re-escapes,
because it changed the bytes). Built-ins, implemented in C:

    upper       uppercase (ASCII fast path, UTF-8 aware)
    lower       lowercase
    trim        strip leading/trailing whitespace
    html        HTML-escape now (marks the value escaped)
    uri         RFC 3986 percent-encoding of the component
    default(x)  replace undef or '' with the literal x

User filters are Perl coderefs registered on the constructor:

    filters => { money => sub { sprintf '%.2f', $_[0] } }

    {% price | money %}
    {% s | repeat(3) %}     # coderef called as ->($value, 3)

A filter argument is a single string or number literal. Unknown filter
names are compile-time errors listing what is registered. A C<die>
inside a filter becomes a render error carrying the filter name and
template location. User filters cost a Perl call - the escape hatch,
not the fast path.

=head2 Conditionals

    {% if expr %} ... {% elsif expr %} ... {% else %} ... {% end %}
    {% unless expr %} ... {% end %}

The expression grammar (no arithmetic or concatenation):

    operands     paths, numbers (42, 3.14, -2), strings ('a' or "a",
                 with \' \" \\ escapes), undef
    numeric      ==  !=  <  >  <=  >=
    string       eq  ne  lt  gt  le  ge
    boolean      && / and,  || / or,  ! / not,  ( ... )
    other        defined(path)

C<&&> and C<||> short-circuit and yield the deciding operand, exactly
like Perl. C<not> binds looser than comparisons, C<&&> tighter than
C<||>. Comparison operators are typed at compile time from their
spelling - C<==> compares numerically, C<eq> compares strings.

Truthiness follows Perl - C<undef>, C<0>, C<''> and C<'0'> are false -
with one deliberate extension: an unblessed B<empty> arrayref or
hashref is also false, so C<{% if items %}> guards a loop naturally.

=head2 Loops

    {% for item in items %} ... {% end %}
    {% for key, value in hash %} ... {% end %}

Arrays bind each element to the named variable. Hashes bind key and
value, iterating in sorted key order by default so output is
deterministic (C<< sort_keys => 0 >> restores raw hash order).
Iterating undef or an empty aggregate renders nothing. Inside a loop
the implicit C<loop> variable is in scope:

    loop.index    0-based index          loop.first   true on first
    loop.index1   1-based index          loop.last    true on last
    loop.size     total iterations       loop.even    parity of index1
    loop.key      current key (hash)     loop.odd     parity of index1

Loops nest arbitrarily; C<loop> always means the innermost. Capture an
outer loop before entering an inner one:

    {% for item in items %}
      {% set item_loop = loop %}
      {% for x in item.list %}
        {% item_loop.index %} / {% loop.index %}
      {% end %}
    {% end %}

=head2 Assignment

    {% set name = expr %}

The value is any expression from the grammar above. The binding lives
in the current block scope: a C<set> inside a C<for> body is fresh
each iteration and gone after C<{% end %}>; a C<set> inside an C<if>
branch dies with the branch; a top-level C<set> lasts to the end of
the template. Bindings shadow data without modifying it.

=head2 Includes

    {% include header.tmpl %}
    {% include header %}        # .tmpl appended when the name has no dot

The name is static, resolved against C<template_dir>. The included
template shares the current scope - it sees loop variables, C<set>
bindings and the root data exactly as the include site does. Includes
are compiled once, linked, and revalidate independently: editing an
include takes effect without recompiling its includers. Include cycles
are compile-time errors naming the cycle. Absolute paths and C<..>
segments are rejected.

=head2 Wrapper (layout)

    my $stencil = Template::Stencil->new(wrapper => 'wrapper.tmpl');

    # wrapper.tmpl
    # <html><body>{% content %}</body></html>

With a wrapper configured, C<render> runs the wrapper and
C<{% content %}> renders the requested template at that point - a
single pass into one buffer, no intermediate string. The wrapper sees
the same data. Override per render with
C<< { wrapper => 'other.tmpl' } >> or disable with
C<< { wrapper => undef } >>. A wrapper without C<{% content %}> is
refused; rendering a template containing C<{% content %}> directly is
a render error; C<{% content %}> runs exactly once.

=head2 Comments and literal braces

    {%# anything, up to the first closing percent-brace %}

Comments are stripped at compile time and may span lines; a comment
may contain C<{%> but not a close. A literal C<{%> in output is
written C<{%%}> (the empty tag). A bare C<%}> or C<}> in text needs no
escaping.

=head1 METHODS

=head2 new

    my $stencil = Template::Stencil->new(%options);
    my $stencil = Template::Stencil->new(\%options);

Builds an engine. Unknown option names croak. Options:

=over 4

=item template_dir => $dir

Base directory for file templates and includes. Must exist and be a
directory. Without it, only string templates (and cwd-relative paths)
work.

=item wrapper => $name

Default layout template; see L</Wrapper (layout)>.

=item filters => { name => sub { ... }, ... }

User filter registry; every value must be a coderef.

=item auto_escape => 1

HTML-escape output tags. Set to 0 to emit everything raw (C<raw> and
the C<html> filter still behave as documented). Default 1.

=item strict => 0

When true, rendering an undef/missing value croaks with the full path
and template location. Conditions and C<defined()> may still test
missing values freely; C<default(...)> can rescue a value before it
reaches output. Default 0.

=item cache => 1

Cache compiled templates. Setting 0 recompiles every render. Default 1.

=item cache_size => 256

Bound on cached string-keyed templates (LRU evicted). File templates
are not bounded. Must be a positive integer.

=item stat_ttl => 1

Seconds between mtime revalidations of cached file templates. C<0>
checks every render, a negative value never re-checks (production:
zero syscalls at steady state). Default 1.

=item sort_keys => 1

Deterministic sorted iteration for C<{% for k, v in hash %}>. Set 0
for raw hash order. Default 1.

=item chars => 0

Return an SvUTF8-flagged character string instead of the default
wire-ready UTF-8 bytes. See L</ENCODING>. Default 0.

=item pretty => 0

Post-format the rendered HTML: whitespace-only lines are removed, then
L<Eshu>'s C<indent_html> re-indents. Eshu is an B<optional> dependency
loaded on first use; requesting C<pretty> without it is an error,
never requesting it costs nothing. Roughly 1.5 microseconds per KB.
Default 0.

=back

=head2 render

    my $out = $stencil->render($template, \%data);
    my $out = $stencil->render($template, \%data, \%opts);

C<$template> is either template source or a file name: an argument
with no newline and no C<{%> that resolves to a file (under
C<template_dir>, or cwd-relative, with C<.tmpl> inference) renders the
file; anything else is treated as source. Rendering equal content from
string and file produces byte-identical output.

C<\%data> is the root scope hashref (optional; missing or undef means
empty). Anything else croaks. The data is never modified.

C<\%opts> overrides per render; unknown keys croak:

    wrapper => $name        use this wrapper (undef disables)
    strict  => 0|1          override strict for this render
    pretty  => 0|1          override pretty for this render

The return value is the render buffer itself - a fresh scalar each
call, safe to hand to a PSGI body arrayref.

Statically resolved calls (C<Template::Stencil::render($s, ...)>) are
rewritten at compile time by a call checker onto a direct C entry
point; method calls use the normal XS path. Both produce identical
results.

=head1 ENCODING

Encoding is the engine's job; callers never C<utf8::encode>. By
default C<render> returns B<wire-ready UTF-8 bytes>: UTF8-flagged
values pass through, unflagged (latin-1 repped) values and template
strings containing high bytes are upgraded automatically, and the
C<uri> filter percent-encodes UTF-8 bytes. C<length($out)> is
therefore the correct Content-Length. Template files are expected to
be UTF-8 (or ASCII) on disk. For non-web use, C<< chars => 1 >>
returns a flagged character string instead.

=head1 ERRORS

All errors croak with the template name (or C<< <string> >>), a line
(and column for compile errors), and a message:

    Template::Stencil: templates/page.tmpl:12:5: unclosed 'if' block
    Template::Stencil: header.tmpl:2: undef value for 'user.name'

Errors inside an include or wrapper name the failing file, not the
page that pulled it in. Unclosed blocks report the opener's position;
mismatched constructs name both ends.

=head1 CONCURRENCY

One engine per interpreter is the model. Prefork servers (Hyperman)
simply construct the object before or after fork - a child inherits a
private copy either way. Under ithreads a cloned object lazily
rebuilds its own engine, with an empty cache, from its cloned options
on first use. No locks exist anywhere because nothing is shared.

=head1 C ABI

An XS module can render through the engine without a Perl frame in
between. F<include/st_abi.h> declares a function-pointer table with two
entries - C<engine_of>, which hands back the opaque engine behind a
blessed Template::Stencil object, and C<render>, which is the render
path minus the XS prologue and the croak. A template error arrives
through an out-parameter rather than as an exception, so a consumer can
turn one into its own error response.

The table is resolved at runtime through C<Template::Stencil::_abi_ptr>
and gated on its C<abi_version>, so there is no link-time coupling and
the two distributions upgrade independently; entries are only ever
appended. Reach the header with L<ExtUtils::Depends>:

    my $pkg = ExtUtils::Depends->new('My::Module', 'Template::Stencil');

Hold a reference to the B<object> and call C<engine_of> on each render
rather than caching the engine pointer: under ithreads a cloned object
drops its engine and rebuilds a fresh one lazily, so a cached handle
would outlive what it points at. The lookup is a walk of the object's
magic chain, which is cheap enough to mean that.

The returned SV belongs to the caller. Do not assign it to a plain
lexical and return that - perl may steal the buffer; store it where it
is going directly.

=head1 CAVEATS

=over 4

=item * Blessed references cannot be traversed in paths (no method
calls in templates) - v0.01 renders data.

=item * Empty unblessed aggregates are false in conditions; this is a
documented extension to Perl truthiness.

=item * Hash-loop key order is sorted bytewise by default.

=item * Reserved words (C<if unless elsif else end for set include raw
content in>) cannot be used in the first position of a tag or as
C<for>/C<set> binding names, though they work fine as data keys.

=item * Dynamic include names, wrapper chains, arithmetic in
expressions, context-aware (attribute/JS/URL) escaping, i18n and
streaming render are reserved hook points for later releases.

=back

=head1 SEE ALSO

L<Hyperman>, L<Template::Stencil::PSGI>, L<Eshu>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-stencil at rt.cpan.org>, or through the web interface
at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Stencil>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Stencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Stencil>

=item * Search CPAN

L<https://metacpan.org/release/Template-Stencil>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
