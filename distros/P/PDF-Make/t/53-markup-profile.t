#!perl

# The template boundary, tested as attacks.
#
# Every case here is written from the position of someone who controls the
# template, the data, or both, and wants out. A passing test means the attempt
# failed; a failing one is a hole. This file is the reason the profile exists,
# so it is deliberately more paranoid than the feature it protects.

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use PDF::Make::Markup::Profile;
use PDF::Make::Markup::Parse;

my $P = 'PDF::Make::Markup::Profile';

eval { require Template::Stencil; 1 }
    or plan skip_all => 'Template::Stencil required for the template profile';

# ---- data cannot become markup ----------------------------------------------

subtest 'a hostile value cannot inject document structure' => sub {
    my @payloads = (
        '</text><pagebreak/><h1>INJECTED</h1><text>',
        '<b>bold</b>',
        '"><img src="x"/>',
        "</text></doc><doc>",
        '&amp;lt;script&amp;gt;',
        "line\nbreak</text>",
    );

    for my $evil (@payloads) {
        my $markup = $P->render('<doc><text>{% v %}</text></doc>', { v => $evil });
        my $r = PDF::Make::Markup::Parse->check($markup);
        ok $r->{ok}, 'the rendered markup still parses'
            or diag "$r->{error}\n$markup";
        next unless $r->{ok};

        my @kids = @{ $r->{root}{children} };
        is scalar @kids, 1, 'the document still has exactly one child';
        is $kids[0]{tag}, 'text', '  and it is the element the template wrote';

        my $text = join '', map { $_->{text} || '' } @{ $kids[0]{children} };
        is $text, $evil, '  with the payload intact as literal text';
    }
};

subtest 'a hostile value cannot break out of an attribute' => sub {
    my $markup = $P->render(
        '<doc><h1 colour="{% c %}">x</h1></doc>',
        { c => '#000" size="99' });
    my $r = PDF::Make::Markup::Parse->check($markup);
    ok $r->{ok}, 'parses' or diag $r->{error};
    my $h1 = $r->{root}{children}[0];
    is scalar keys %{ $h1->{attrs} }, 1, 'still one attribute';
    is $h1->{attrs}{colour}, '#000" size="99',
        'the quote inside it stayed data';
};

subtest 'escaping cannot be turned off' => sub {
    eval { $P->engine(auto_escape => 0) };
    like $@, qr/'auto_escape' cannot be set/, 'not by an option';

    eval { $P->engine(auto_escape => 1) };
    like $@, qr/'auto_escape' cannot be set/,
        'not even by passing the value it already has';
};

subtest '{% raw %} is refused, with a line number' => sub {
    for my $src ('{% raw v %}', "{%raw v%}", "{%  raw   v %}") {
        eval { $P->check_source("<doc><text>$src</text></doc>") };
        like $@, qr/\{% raw %\} is not available/, "refused: $src";
    }

    eval { $P->check_source(qq{<doc>\n  <text>a</text>\n  <text>{% raw v %}</text>\n</doc>}) };
    like $@, qr/template error at line 3/, 'the line is reported';
    like $@, qr/Values are escaped; markup belongs in the template/,
        'and the message says what to do instead';

    # the ordinary form is untouched
    eval { $P->check_source('<doc><text>{% v %}</text></doc>') };
    is $@, '', 'an ordinary interpolation is fine';

    # a template that merely mentions the word is not a false positive
    eval { $P->check_source('<doc><text>raw materials {% v %}</text></doc>') };
    is $@, '', 'the word "raw" in prose is not a construct';
};

# ---- templates cannot reach code --------------------------------------------

subtest 'filters cannot be supplied by a caller' => sub {
    eval { $P->engine(filters => { evil => sub { 'pwned' } }) };
    like $@, qr/'filters' cannot be set/,
        'the one hook that takes a coderef is closed';

    eval { $P->engine(filters => {}) };
    like $@, qr/'filters' cannot be set/, 'even an empty one';
};

subtest 'the filter list is what it says it is' => sub {
    my @names = $P->filter_names;
    is_deeply \@names, [qw(money number)], 'exactly the documented additions';

    my $f = $P->filters;
    is $f->{money}->(1240.5),   '1,240.50', 'money formats';
    is $f->{money}->(-99),      '-99.00',   '  including negatives';
    is $f->{money}->('abc'),    '',         '  and refuses nonsense';
    is $f->{number}->(1234567), '1,234,567', 'number groups';

    # mutating the returned map must not change the engine's
    $f->{money} = sub { 'tampered' };
    is $P->filters->{money}->(1), '1.00', 'the map handed out is a copy';
};

subtest 'a template calling an unknown filter fails' => sub {
    my $out = eval { $P->render('<doc><text>{% v | nosuchfilter %}</text></doc>',
                                { v => 'x' }) };
    ok !defined $out, 'the render did not silently succeed' or diag $out;
};

# ---- includes ---------------------------------------------------------------

subtest 'includes cannot climb out of the bundle' => sub {
    my $dir = tempdir(CLEANUP => 1);
    open my $fh, ">", "$dir/partial.tmpl" or die $!;
    print $fh '<text>included</text>';
    close $fh;

    my $engine = $P->engine(template_dir => $dir, cache => 0);
    my $ok = eval {
        $P->render('<doc>{% include partial.tmpl %}</doc>', {}, engine => $engine)
    };
    ok defined $ok, 'a partial inside the bundle is included' or diag $@;
    like $ok, qr/included/, '  and its content appears' if defined $ok;

    for my $escape ('../../../../etc/passwd', '/etc/passwd',
                    '..%2f..%2fetc%2fpasswd', 'sub/../../../etc/passwd') {
        my $out = eval {
            $P->render(qq{<doc>{% include $escape %}</doc>}, {},
                       engine => $engine)
        };
        ok !defined($out) || $out !~ /root:/,
            "no file outside the bundle through '$escape'";
    }
};

# ---- resource limits --------------------------------------------------------

subtest 'output is capped' => sub {
    my $big = 'x' x 5000;
    my $out = eval {
        $P->render('<doc><text>{% v %}</text></doc>', { v => $big },
                   max_output => 1000)
    };
    ok !defined $out, 'a template over the cap does not return markup';
    like $@, qr/over the 1000 byte limit/, 'and says so with the numbers';

    $out = eval {
        $P->render('<doc><text>{% v %}</text></doc>', { v => 'small' },
                   max_output => 1000)
    };
    ok defined $out, 'one under the cap renders';
};

subtest 'strictness catches a field the data does not have' => sub {
    my $out = eval { $P->render('<doc><text>{% missing %}</text></doc>', {}) };
    ok !defined $out, 'a missing field does not render as a blank space'
        or diag "rendered: $out";
};

# ---- the round trip ---------------------------------------------------------

subtest 'ordinary documents still work' => sub {
    my $data = {
        n     => 1042,
        total => 1240.5,
        lines => [ { name => 'Widget & Co', qty => 2 },
                   { name => 'Gadget',      qty => 1 } ],
    };
    my $markup = $P->render(<<'TPL', $data);
<doc>
  <h1>Invoice {% n %}</h1>
  <table>
    {% for l in lines %}
    <tr><td>{% l.name %}</td><td>{% l.qty %}</td></tr>
    {% end %}
  </table>
  <text>Total: {% total | money %}</text>
</doc>
TPL

    my $r = PDF::Make::Markup::Parse->check($markup);
    ok $r->{ok}, 'the rendered document parses' or diag "$r->{error}\n$markup";
    like $markup, qr/1,240\.50/, 'the money filter ran';
    like $markup, qr/Widget &amp; Co/, 'and the ampersand in the data is escaped';

    my ($table) = grep { $_->{tag} eq 'table' } @{ $r->{root}{children} };
    is scalar @{ $table->{children} }, 2, 'the loop produced two rows';
};

done_testing;
