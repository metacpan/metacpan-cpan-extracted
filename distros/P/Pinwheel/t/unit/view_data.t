#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 148;

use Pinwheel::View::Data;


my $testnum = 0;

sub mkname
{
    $testnum += 1;
    return "test/test${testnum}";
}

# Naive JSON decoder, only intended for testing View::Data JSON output
sub json_decode
{
    my ($s) = @_;
    my ($v, $expr);

    $expr = '';
    while (1) {
        if ($s =~ /\G"((?:\\u[0-9a-fA-F]{4}|\\[\\\/"bfnrt]|[^"])*)"/gc) {
            $v = $1;
            $v =~ s/\\u(....)/utf8_escapes(hex($1))/ge;
            $v =~ s/\$/\\\$/g;
            $expr .= "\"$v\"";
        } elsif ($s =~ /\G(-?[0-9]+(?:\.[0-9]+)?(?:[Ee][+-]?[0-9]+)?)/gc) {
            $expr .= $1;
        } elsif ($s =~ /\Gnull/gc) {
            $expr .= 'undef';
        } elsif ($s =~ /\G(?:(true)|false)/gc) {
            $expr .= $1 ? '1' : '0';
        } elsif ($s =~ /\G:/gc) {
            $expr .= '=>';
        } elsif ($s =~ /\G([\[\]{},])/gc) {
            $expr .= $1;
        } elsif ($s =~ /\G\s+/gc) {
            # Ignore whitespace between tokens
        } elsif ($s =~ /\G./gc) {
            return undef;
        } else {
            last;
        }
    }

    return eval $expr;
}

sub html_json_decode
{
    my ($s) = @_;

    $s =~ s/.+?<body>//s;
    $s =~ s/<.+?>//g;
    $s =~ s/&#(\d+);/utf8_bytes($1)/ge;
    $s =~ s/&lt;/</g;
    $s =~ s/&gt;/>/g;
    $s =~ s/&quot;/"/g;
    $s =~ s/&amp;/&/g;
    return json_decode($s);
}

sub utf8_encode
{
    my ($i) = @_;
    my ($b1, @bytes);

    return $i if ($i < 0x80);

    $b1 = 0xf00;
    while ($i != 0) {
        push @bytes, 0x80 | ($i & 0x3f);
        $i >>= 6;
        $b1 >>= 1;
    }
    $bytes[-1] |= $b1 & 0xff;

    return reverse(@bytes);
}

sub utf8_escapes
{
    return join('', map { sprintf('\x%02d', $_) } utf8_encode(@_));
}

sub utf8_bytes
{
    return join('', map { chr($_) } utf8_encode(@_));
}


# Package name for compiled templates
{
    my ($pkg);

    Pinwheel::View::Data::parse_template('x()', 'abc/def.ghi')->({}, {}, {});
    $pkg = \%Pinwheel::View::Data::Template::abc::;
    ok(defined($pkg->{'def::'}));

    Pinwheel::View::Data::parse_template('x()', 'a-b/c-d.efg')->({}, {}, {});
    $pkg = \%Pinwheel::View::Data::Template::a_b::;
    ok(defined($pkg->{'c_d::'}));

    Pinwheel::View::Data::parse_template('x()', 'i--j--k/x---y---z.txt')->({}, {}, {});
    $pkg = \%Pinwheel::View::Data::Template::i_j_k::;
    ok(defined($pkg->{'x_y_z::'}));

    Pinwheel::View::Data::parse_template('x()', 'test/123.foo')->({}, {}, {});
    $pkg = \%Pinwheel::View::Data::Template::test::;
    ok(defined($pkg->{'_123::'}));
}

# Invalid templates
{
    eval { Pinwheel::View::Data::parse_template('x{', mkname()) };
    like($@, qr/syntax error/i);
}

# Parameter detection
{
    my ($p);

    $p = Pinwheel::View::Data::find_parameters('1');
    is_deeply($p, {});

    $p = Pinwheel::View::Data::find_parameters('$v');
    is_deeply($p, {'$v' => 1});
    $p = Pinwheel::View::Data::find_parameters('my $v');
    is_deeply($p, {});
    $p = Pinwheel::View::Data::find_parameters('my $v = $a');
    is_deeply($p, {'$a' => 1});
    $p = Pinwheel::View::Data::find_parameters('my ($v, $w) = ($a, $b)');
    is_deeply($p, {'$a' => 1, '$b' => 1});
    $p = Pinwheel::View::Data::find_parameters('my ($v, $w) = @_');
    is_deeply($p, {});
    $p = Pinwheel::View::Data::find_parameters('my ($v, $w) = @a');
    is_deeply($p, {});
    $p = Pinwheel::View::Data::find_parameters('my $v = $_');
    is_deeply($p, {});

    $p = Pinwheel::View::Data::find_parameters('sub f { $v }');
    is_deeply($p, {'$v' => 1});
    $p = Pinwheel::View::Data::find_parameters('sub f { my $v }');
    is_deeply($p, {});

    $p = Pinwheel::View::Data::find_parameters('my ($v); sub f { $v }');
    is_deeply($p, {});
    $p = Pinwheel::View::Data::find_parameters('sub f { my $v }; $v');
    is_deeply($p, {'$v' => 1});

    $p = Pinwheel::View::Data::find_parameters('$a; sub f { $b }');
    is_deeply($p, {'$a' => 1, '$b' => 1});
    $p = Pinwheel::View::Data::find_parameters('$a; sub f { $b }; sub g { $c }');
    is_deeply($p, {'$a' => 1, '$b' => 1, '$c' => 1});
    $p = Pinwheel::View::Data::find_parameters('my $a = $x; sub f { $b }');
    is_deeply($p, {'$x' => 1, '$b' => 1});
}

# JSON rendering
{
    my ($render, $s);

    $render = sub {
        my $template = Pinwheel::View::Data::parse_template($_[0], mkname());
        return $template->({}, {}, {})->to_json();
    };

    $s = &$render('a()');
    is($s, '{"a":null}');

    $s = &$render('TAG("sub")');
    is($s, '{"sub":null}');

    $s = &$render('a(sub { b() })');
    is($s, '{"a":{"b":null}}');
    $s = &$render('a(sub { b(); c() })');
    is($s, '{"a":{"b":null,"c":null}}');

    $s = &$render('a("text")');
    is($s, '{"a":"text"}');
    $s = &$render('TAG("if", "text")');
    is($s, '{"if":"text"}');
    $s = &$render("a(\"one\t\xc2\xa0two\")");
    is($s, "{\"a\":\"one\\u0009\xc2\xa0two\"}");
    $s = &$render('a("one\"two")');
    is($s, '{"a":"one\"two"}');

    $s = &$render('a(42)');
    is($s, '{"a":42}');
    $s = &$render('a(-42)');
    is($s, '{"a":-42}');
    $s = &$render('a(3.14)');
    is($s, '{"a":3.14}');
    $s = &$render('a(-3.14)');
    is($s, '{"a":-3.14}');

    $s = &$render('a(x => "one")');
    is($s, '{"a":{"x":"one"}}');
    $s = &$render('a(x => undef)');
    is($s, '{"a":{"x":null}}');
    $s = &$render('a(x => 42)');
    is($s, '{"a":{"x":42}}');
    $s = &$render('a(x => "one", "two")');
    is($s, '{"a":{"x":"one","$t":"two"}}');
    $s = &$render('a(x => "one", undef)');
    is($s, '{"a":{"x":"one"}}');
    $s = &$render('a(x => "one", sub { two() })');
    is($s, '{"a":{"x":"one","two":null}}');

    $s = &$render('list_(sub { })');
    is($s, '{"list":[]}');
    $s = &$render('list_(sub { item("a"); item("b"); item("c") })');
    is($s, '{"list":["a","b","c"]}');
    $s = &$render('list_(sub { item("a"); item(b => "one"); item("c") })');
    is($s, '{"list":["a",{"b":"one"},"c"]}');

    $s = &$render('TAG("a:b", "text")');
    is($s, '{"a$b":"text"}');
    $s = &$render('a("x:y" => "foo")');
    is($s, '{"a":{"x$y":"foo"}}');
    $s = &$render('a("x:y" => "foo", sub { b() })');
    is($s, '{"a":{"x$y":"foo","b":null}}');
}

# HTML rendering
{
    my ($render, $s);

    $render = sub {
        my $template = Pinwheel::View::Data::parse_template($_[0], mkname());
        my @lines = split(/\n/, $template->({}, {}, {})->to_html());
        return $lines[-2];
    };

    $s = &$render('a()');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="null">null</span></div>}</div>');

    $s = &$render('TAG("sub")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"sub"</span>: <span class="null">null</span></div>}</div>');

    $s = &$render('a(sub { b() })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"b"</span>: <span class="null">null</span></div>}</div>}</div>');
    $s = &$render('a(sub { b(); c() })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"b"</span>: <span class="null">null</span>,</div><div class="indent"><span class="key">"c"</span>: <span class="null">null</span></div>}</div>}</div>');

    $s = &$render('a("text")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">&quot;text&quot;</span></div>}</div>');
    $s = &$render('TAG("if", "text")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"if"</span>: <span class="literal">&quot;text&quot;</span></div>}</div>');
    $s = &$render("a(\"one\t\xc2\xa0two\")");
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">&quot;one\u0009&#160;two&quot;</span></div>}</div>');
    $s = &$render('a("one\"two")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">&quot;one\&quot;two&quot;</span></div>}</div>');

    $s = &$render('a(42)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">42</span></div>}</div>');
    $s = &$render('a(-42)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">-42</span></div>}</div>');
    $s = &$render('a(3.14)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">3.14</span></div>}</div>');
    $s = &$render('a(-3.14)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: <span class="literal">-3.14</span></div>}</div>');

    $s = &$render('a(x => "one")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="literal">&quot;one&quot;</span></div>}</div>}</div>');
    $s = &$render('a(x => undef)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="null">null</span></div>}</div>}</div>');
    $s = &$render('a(x => 42)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="literal">42</span></div>}</div>}</div>');
    $s = &$render('a(x => "one", "two")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="literal">&quot;one&quot;</span>,</div><div class="indent"><span class="key">"$t"</span>: <span class="literal">&quot;two&quot;</span></div>}</div>}</div>');
    $s = &$render('a(x => "one", undef)');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="literal">&quot;one&quot;</span></div>}</div>}</div>');
    $s = &$render('a(x => "one", sub { two() })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x"</span>: <span class="literal">&quot;one&quot;</span>,</div><div class="indent"><span class="key">"two"</span>: <span class="null">null</span></div>}</div>}</div>');

    $s = &$render('list_(sub { })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"list"</span>: []</div>}</div>');
    $s = &$render('list_(sub { item("a"); item("b"); item("c") })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"list"</span>: [<div class="indent"><span class="literal">&quot;a&quot;</span>,</div><div class="indent"><span class="literal">&quot;b&quot;</span>,</div><div class="indent"><span class="literal">&quot;c&quot;</span></div>]</div>}</div>');
    $s = &$render('list_(sub { item("a"); item(b => "one"); item("c") })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"list"</span>: [<div class="indent"><span class="literal">&quot;a&quot;</span>,</div><div class="indent">{<div class="indent"><span class="key">"b"</span>: <span class="literal">&quot;one&quot;</span></div>},</div><div class="indent"><span class="literal">&quot;c&quot;</span></div>]</div>}</div>');

    $s = &$render('TAG("a:b", "text")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a$b"</span>: <span class="literal">&quot;text&quot;</span></div>}</div>');
    $s = &$render('a("x:y" => "foo")');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x$y"</span>: <span class="literal">&quot;foo&quot;</span></div>}</div>}</div>');
    $s = &$render('a("x:y" => "foo", sub { b() })');
    is($s, '<div class="code">{<div class="indent"><span class="key">"a"</span>: {<div class="indent"><span class="key">"x$y"</span>: <span class="literal">&quot;foo&quot;</span>,</div><div class="indent"><span class="key">"b"</span>: <span class="null">null</span></div>}</div>}</div>');
}

# JSON and HTML-wrapped JSON should contain the same data
{
    my ($is_same);

    $is_same = sub {
        my $template = Pinwheel::View::Data::parse_template($_[0], mkname());
        my $data = $template->({}, {}, {});
        my $j1 = $data->to_json;
        my $j2 = $data->to_html;
        is_deeply(json_decode($j1), html_json_decode($j2));
    };

    &$is_same('a()');
    &$is_same('TAG("a:b")');
    &$is_same('a(sub { b() })');
    &$is_same('a("text")');
    &$is_same("a(\"one\t\xc2\xa2\xe2\x82\xac\xf4\x8a\xaf\x8dtwo\")");
    &$is_same('a(x => 1)');
    &$is_same('a("x:y" => 1)');
    &$is_same('a(x => 1, y => 2, z => 3)');
    &$is_same('a(x => 1, "text")');
    &$is_same('a(x => 1, sub { b("text") })');
    &$is_same('a_(sub { i(10); i(20); i(30) })');
}

# YAML rendering
{
    my ($render, $s);

    $render = sub {
        my $template = Pinwheel::View::Data::parse_template($_[0], mkname());
        return $template->({}, {}, {})->to_yaml();
    };

    $s = &$render('a()');
    is($s, "a: ~\n");

    $s = &$render('TAG("sub")');
    is($s, "sub: ~\n");

    $s = &$render('a(sub { b() })');
    is($s, <<'END');
a:
  b: ~
END
    $s = &$render('a(sub { b(); c() })');
    is($s, <<'END');
a:
  b: ~
  c: ~
END

    $s = &$render('a("text")');
    is($s, <<'END');
a: "text"
END
    $s = &$render('TAG("if", "text")');
    is($s, <<'END');
if: "text"
END
    $s = &$render("a(\"one\t\n\xc2\xa0\xe2\x80\xa8two\xe2\x80\xa9\")");
    is($s, <<END);
a: "one\t\\x0a\xc2\xa0\\u2028two\\u2029"
END
    $s = &$render("a(\"\xed\xa0\x80\xed\xbf\x80\xed\xa0\xbf\xed\xbf\xbf\")");
    is($s, <<'END');
a: "\ud800\udfc0\ud83f\udfff"
END
    $s = &$render('a("one\"two")');
    is($s, <<END);
a: "one\\"two"
END

    $s = &$render('a(42)');
    is($s, "a: 42\n");
    $s = &$render('a(-42)');
    is($s, "a: -42\n");
    $s = &$render('a(3.14)');
    is($s, "a: 3.14\n");
    $s = &$render('a(-3.14)');
    is($s, "a: -3.14\n");

    $s = &$render('a(x => "one")');
    is($s, <<'END');
a:
  x: "one"
END
    $s = &$render('a(x => undef)');
    is($s, <<'END');
a:
  x: ~
END
    $s = &$render('a(x => 42)');
    is($s, <<'END');
a:
  x: 42
END
    $s = &$render('a(x => "one", "two")');
    is($s, <<'END');
a:
  x: "one"
  $t: "two"
END
    $s = &$render('a(x => "one", undef)');
    is($s, <<'END');
a:
  x: "one"
END
    $s = &$render('a(x => "one", sub { two() })');
    is($s, <<'END');
a:
  x: "one"
  two: ~
END

    $s = &$render('data(sub { })');
    is($s, <<'END');
data: {}
END
    $s = &$render('list_(sub { })');
    is($s, <<'END');
list: []
END
    $s = &$render('list_(sub { item("a"); item("b"); item("c") })');
    is($s, <<'END');
list:
  - "a"
  - "b"
  - "c"
END
    $s = &$render('list_(sub { item("a"); item(b => "one"); item("c") })');
    is($s, <<'END');
list:
  - "a"
  - b: "one"
  - "c"
END
    $s = &$render('x(sub { l_(sub { i("a"); i("b") }); h(sub { a("b") }) })');
    is($s, <<'END');
x:
  l:
    - "a"
    - "b"
  h:
    a: "b"
END
    $s = &$render('l_(sub { i(sub { a(1); b(2) }); i(sub { c(3) }) })');
    is($s, <<'END');
l:
  - a: 1
    b: 2
  - c: 3
END

    $s = &$render('TAG("a:b", "text")');
    is($s, <<'END');
a$b: "text"
END
    $s = &$render('a("x:y" => "foo")');
    is($s, <<'END');
a:
  x$y: "foo"
END
    $s = &$render('a("x:y" => "foo", sub { b() })');
    is($s, <<'END');
a:
  x$y: "foo"
  b: ~
END
}

# XML rendering
{
    my ($build, $render, $s);

    $build = sub {
        my $template = Pinwheel::View::Data::parse_template($_[0], mkname());
        return $template->({}, {}, {});
    };
    $render = sub {
        return substr(&$build(@_)->to_xml(), 22);
    };

    is(&$build('a()')->to_xml(), "<?xml version=\"1.0\"?>\n<a/>");

    $s = &$render('a()');
    is($s, '<a/>');

    $s = &$render('TAG("sub")');
    is($s, '<sub/>');

    $s = &$render('a(sub { b() })');
    is($s, '<a><b/></a>');
    $s = &$render('a(sub { b(); c() })');
    is($s, '<a><b/><c/></a>');

    $s = &$render('a("text")');
    is($s, '<a>text</a>');
    $s = &$render('TAG("if", "text")');
    is($s, '<if>text</if>');
    $s = &$render("a(\"one\t\xc2\xa0two\")");
    is($s, "<a>one\t\xc2\xa0two</a>");
    $s = &$render('a("one\"&\"two")');
    is($s, '<a>one&quot;&amp;&quot;two</a>');

    $s = &$render('a(42)');
    is($s, '<a>42</a>');
    $s = &$render('a(3.14)');
    is($s, '<a>3.14</a>');

    $s = &$render('a(x => "one")');
    is($s, '<a x="one"/>');
    $s = &$render('a(x => "one&two")');
    is($s, '<a x="one&amp;two"/>');
    $s = &$render('a(x => undef)');
    is($s, '<a x=""/>');
    $s = &$render('a(x => 42)');
    is($s, '<a x="42"/>');
    $s = &$render('a(x => "one", "two")');
    is($s, '<a x="one">two</a>');
    $s = &$render('a(x => "one", undef)');
    is($s, '<a x="one"/>');
    $s = &$render('a(x => "one", sub { two() })');
    is($s, '<a x="one"><two/></a>');

    $s = &$render('list_(sub { })');
    is($s, '<list></list>');
    $s = &$render('list_(sub { item("a"); item("b"); item("c") })');
    is($s, '<list><item>a</item><item>b</item><item>c</item></list>');
    $s = &$render('list_(sub { item("a"); item(b => "one"); item("c") })');
    is($s, '<list><item>a</item><item b="one"/><item>c</item></list>');

    $s = &$render('TAG("a:b", "text")');
    is($s, '<a:b>text</a:b>');
    $s = &$render('a("x:y" => "foo")');
    is($s, '<a x:y="foo"/>');
    $s = &$render('a("x:y" => "foo", sub { b() })');
    is($s, '<a x:y="foo"><b/></a>');
}

# Parameters passed to templates
{
    my ($fn, $d);

    $fn = Pinwheel::View::Data::parse_template('r(10)', mkname());
    is_deeply(&$fn({}, {}, {})->to_json(), '{"r":10}');

    $fn = Pinwheel::View::Data::parse_template('r($v)', mkname());
    is_deeply(&$fn({v => 20}, {}, {})->to_json(), '{"r":20}');
    is_deeply(&$fn({}, {v => 30}, {})->to_json(), '{"r":30}');
    eval { &$fn({}, {}, {}) };
    like($@, qr/missing parameter 'v'/i);

    # Locals override globals
    $fn = Pinwheel::View::Data::parse_template('r($v)', mkname());
    is_deeply(&$fn({v => 40}, {v => 50}, {})->to_json(), '{"r":40}');

    # Helper functions are exposed through $h
    $fn = Pinwheel::View::Data::parse_template('r($h->{f}())', mkname());
    is_deeply(&$fn({}, {}, {f => sub { 60 }})->to_json(), '{"r":60}');

    # $h cannot be overridden
    $fn = Pinwheel::View::Data::parse_template('r($h->{f}())', mkname());
    $d = &$fn({h => 70}, {h => 80}, {f => sub { 90 }});
    is_deeply($d->to_json(), '{"r":90}');
}

# String renderings
{
    my ($render, $d);

    $render = sub {
        my $fn = Pinwheel::View::Data::parse_template($_[0], mkname());
        my $d = $fn->({}, {}, {});
        return $d;
    };

    $d = &$render('a(href => "foo", "bar")');
    is($d->to_xml . "\n", <<'EOF');
<?xml version="1.0"?>
<a href="foo">bar</a>
EOF
    is($d->to_json, '{"a":{"href":"foo","$t":"bar"}}');
    is($d->to_yaml, <<'EOF');
a:
  href: "foo"
  $t: "bar"
EOF

    is($d->to_string('xml'), $d->to_xml);
    is($d->to_string('atom'), $d->to_xml);
    is($d->to_string('rss'), $d->to_xml);
    is($d->to_string('json'), $d->to_json);
    is($d->to_string('yaml'), $d->to_yaml);
    is($d->to_string('html'), $d->to_html);
    eval { $d->to_string('foo') };
    like($@, qr/unsupported/i);
}


Pinwheel::View::Data::_clear_templates();
