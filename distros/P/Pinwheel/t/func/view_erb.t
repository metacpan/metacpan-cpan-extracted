#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 231;

use Pinwheel::View::ERB;


sub compile
{
    my $writer = Pinwheel::View::ERB::code_writer('test');
    Pinwheel::View::ERB::parse_code(Pinwheel::View::ERB::lexer($_), $writer, 1) foreach (@_);
    my $t = Pinwheel::View::ERB::compile($writer->{eof}());
    return sub { $t->(@_)->to_string() };
}

sub template
{
    my $code = Pinwheel::View::ERB::parse_template(@_);
    return sub { my $s = &$code(@_); "$s" };
}

sub no_warnings(&)
{
    local $SIG{__WARN__} = sub {};
    $_[0]->();
}


{
    package MockModel;
    our $AUTOLOAD;
    sub new { bless({}, shift) }
    sub AUTOLOAD { my $m = $AUTOLOAD; $m =~ s/.*://; uc($m) x 2 }
}

{
    package MockAddable;
    sub new {
        my ($class, $v) = @_;
        return bless({v => $v}, $class);
    }
    sub add { $_[0]->{v} + $_[1] }
    sub radd { $_[0]->{v} + $_[1] }
}


# Evaluation
{
    my ($code, $locals, $globals, $obj);

    # Mathematics
    $code = compile('1 + 2');
    is(&$code({}, {}, {}), 3);
    $code = compile('1 + 2 + 3');
    is(&$code({}, {}, {}), 6);
    $code = compile('1 + 2 - 3');
    is(&$code({}, {}, {}), 0);
    $code = compile('1 + 2 * 3');
    is(&$code({}, {}, {}), 7);
    $code = compile('(1 + 2) * 3');
    is(&$code({}, {}, {}), 9);
    $code = compile('8 / 2');
    is(&$code({}, {}, {}), 4);
    $code = compile('8 % 2');
    is(&$code({}, {}, {}), 0);
    $code = compile('7 % 2');
    is(&$code({}, {}, {}), 1);
    $code = compile('8 / 2 + 1');
    is(&$code({}, {}, {}), 5);
    $code = compile('-x');
    is(&$code({x => 12}, {}, {}), -12);

    # Hash literals
    $code = compile('fn({})');
    is(&$code({}, {}, {fn => sub { $obj = $_[0]; 'x' }}), 'x');
    is(scalar(keys(%$obj)), 0);
    $code = compile('fn({:a => 10})');
    is(&$code({}, {}, {fn => sub { $obj = $_[0]; 'x' }}), 'x');
    is(scalar(keys(%$obj)), 1);
    is($obj->{a}, 10);
    $code = compile('fn({:a => 10, :b => 20})');
    is(&$code({}, {}, {fn => sub { $obj = $_[0]; 'x' }}), 'x');
    is(scalar(keys(%$obj)), 2);
    is($obj->{a}, 10);
    is($obj->{b}, 20);
    $code = compile('fn(1, {:a => 10})');
    is(&$code({}, {}, {fn => sub { $obj = \@_; 'x' }}), 'x');
    is(scalar(@$obj), 2);
    is(scalar(keys(%{$obj->[1]})), 1);
    is($obj->[1]{a}, 10);
    eval { compile('{ x') };
    like($@, qr/expected key/i);
    eval { compile('{ :x 1') };
    like($@, qr/expected '=>'/i);
    eval { compile('{ :x => 1 2') };
    like($@, qr/missing }/i);

    # Concatenation
    # (addition when left and right are /^-?\d+$/, concatenation otherwise)
    $code = compile('"a" + "b"');
    is(&$code({}, {}, {}), 'ab');
    $code = compile('"a" + "1"');
    is(&$code({}, {}, {}), 'a1');
    $code = compile('"1" + "b"');
    is(&$code({}, {}, {}), '1b');
    $code = compile('"1" + "2"');
    is(&$code({}, {}, {}), 3);

    # Delegated add
    $code = compile('x + 2');
    is(&$code({x => MockAddable->new(4)}, {}, {}), '6');
    $code = compile('2 + x');
    is(&$code({x => MockAddable->new(4)}, {}, {}), '6');

    # Variables
    $code = compile('x');
    is(&$code({x => 9}, {}, {}), 9);
    no_warnings { is(&$code({}, {}, {}), '') };
    $code = compile('x + 2');
    is(&$code({x => 9}, {}, {}), 11);
    $code = compile('@x');
    is(&$code({}, {x => 9}, {}), 9);
    $code = compile('-x');
    is(&$code({x => 42}, {}, {}), -42);

    # Assignment (locals)
    $locals = {};
    &{compile('x = 4')}($locals, {}, {});
    is($locals->{x}, 4);
    &{compile('x = x + 5')}($locals, {}, {});
    is($locals->{x}, 9);
    &{compile('y = 10')}($locals, {}, {});
    is($locals->{y}, 10);
    &{compile('x = x + y')}($locals, {}, {});
    is($locals->{x}, 19);
    &{compile('x = "hello world"')}($locals, {}, {});
    is($locals->{x}, 'hello world');
    &{compile('x = foo()')}($locals, {}, {foo => sub { 100 }});
    is($locals->{x}, 100);

    # Assignment (globals)
    $globals = {x => 10};
    &{compile('@x')}({}, $globals, {});
    is($globals->{x}, 10);
    &{compile('@x = @x * 5')}({}, $globals, {});
    is($globals->{x}, 50);

    # Unpacking
    $locals = {};
    &{compile('x, y = f()')}($locals, {}, {f => sub { [10, 20] }});
    is($locals->{x}, 10);
    is($locals->{y}, 20);
    &{compile('a, b, c = f()')}($locals, {}, {f => sub { [10, 20, 40] }});
    is($locals->{a}, 10);
    is($locals->{b}, 20);
    is($locals->{c}, 40);
    &{compile('x, y = f()')}($locals, {}, {f => sub { [10] }});
    is($locals->{x}, 10);
    is($locals->{y}, undef);
    $locals->{l} = [1, 2, 4];
    &{compile('x, y, z = l')}($locals, {}, {});
    is($locals->{x}, 1);
    is($locals->{y}, 2);
    is($locals->{z}, 4);

    # Attributes
    $code = compile('x.y');
    is(&$code({x => {y => 4}}, {}, {}), 4);
    $code = compile('x.y.z');
    is(&$code({x => {y => {z => 42}}}, {}, {}), 42);
    $code = compile('@foo.bar');
    is(&$code({}, {foo => {bar => 3}}), 3);
    $obj = MockModel->new();
    $code = compile('obj.c + obj.a + obj.b');
    is(&$code({obj => $obj}, {}, {}), 'CCAABB');
    $code = compile('@obj.a');
    is(&$code({}, {obj => $obj}, {}), 'AA');

    $code = compile('s.length');
    is(&$code({s => 'hello'}, {}, {}), 5);
    $code = compile('s.size');
    is(&$code({s => 'hello'}, {}, {}), 5);
    $code = compile('s.strip');
    is(&$code({s => '  abc  '}, {}, {}), 'abc');
    $code = compile('s.strip.length');
    is(&$code({s => '  abc  '}, {}, {}), 3);
    $code = compile('s.strip.blah');
    eval { &$code({s => 's'}, {}, {}) };
    like($@, qr/bad scalar method/i);

    $code = compile('obj.empty');
    ok(&$code({obj => []}, {}, {}));
    ok(!&$code({obj => [123]}, {}, {}));
    $code = compile('obj.size');
    is(&$code({obj => [10, 20, 30]}, {}, {}), 3);
    $code = compile('obj.length');
    is(&$code({obj => [10, 20, 30]}, {}, {}), 3);
    $code = compile('obj.first');
    is(&$code({obj => [10, 20, 30]}, {}, {}), 10);
    $code = compile('obj.last');
    is(&$code({obj => [10, 20, 30]}, {}, {}), 30);
    $code = compile('obj.first.a');
    is(&$code({obj => [$obj]}, {}, {}), 'AA');
    $code = compile('obj.first.x');
    is(&$code({obj => [{x => 'y'}]}, {}, {}), 'y');
    eval { &{compile('x.y')}({x => 1}, {}, {}) };
    like($@, qr/can't call method/i);
    eval { &{compile('x.first.blah')}({x => [[10]]}, {}, {}) };
    like($@, qr/bad array method/i);

    # Hash access
    $code = compile('x["k1"]');
    is(&$code({x => {k1 => 'v1'}}, {}, {}), 'v1');
    $code = compile('x[:k1]');
    is(&$code({x => {k1 => 'v1'}}, {}, {}), 'v1');
    $code = compile('x[y]');
    is(&$code({x => {k2 => 'v2'}, y => 'k2'}, {}, {}), 'v2');
    $code = compile('x.first["k3"]');
    is(&$code({x => [{k3 => 'v3'}]}, {}, {}), 'v3');
    $code = compile('x.first[y]');
    is(&$code({x => [{k4 => 'v4'}, {k4 => 'x'}], y => 'k4'}, {}, {}), 'v4');
    $code = compile('x["k5"].first');
    is(&$code({x => {k5 => ['v5', 'a']}}, {}, {}), 'v5');
    $code = compile('x[y].first');
    is(&$code({x => {k6 => ['v6', 'a']}, y => 'k6'}, {}, {}), 'v6');
    $code = compile('x["y"]["z"]');
    is(&$code({x => {y => {z => 'hello'}}}, {}, {}), 'hello');
    $code = compile('x[y["z"]]');
    is(&$code({x => {k => 'yes'}, y => {z => 'k'}}, {}, {}), 'yes');
    eval { &{compile('x["y"')}({x => {y => 'z'}}, {}, {}) };
    like($@, qr/expected ']'/i);

    # Negation
    $code = compile('!1');
    ok(!&$code({}, {}, {}));
    $code = compile('!!4');
    ok(&$code({}, {}, {}));
    $code = compile('!x');
    ok(&$code({x => 0}, {}, {}));
    ok(!&$code({x => 2}, {}, {}));
    ok(&$code({x => ''}, {}, {}));
    ok(!&$code({x => {}}, {}, {}));
    ok(!&$code({x => []}, {}, {}));
    ok(&$code({x => undef}, {}, {}));
    $code = compile('!!x');
    ok(!&$code({x => 0}, {}, {}));
    ok(&$code({x => 2}, {}, {}));
    ok(!&$code({x => ''}, {}, {}));
    ok(&$code({x => {}}, {}, {}));
    ok(&$code({x => []}, {}, {}));
    ok(!&$code({x => undef}, {}, {}));
    $code = compile('!(x + 1)');
    ok(&$code({x => -1}, {}, {}));

    # Truth
    $code = compile('if x', '"t"', 'end');
    is(&$code({x => 0}, {}, {}), '');
    is(&$code({x => {}}, {}, {}), 't');
    is(&$code({x => []}, {}, {}), 't');
    is(&$code({x => [0]}, {}, {}), 't');
    is(&$code({x => {a => 2}}, {}, {}), 't');
    $code = compile('if !x', '"t"', 'end');
    is(&$code({x => 0}, {}, {}), 't');
    is(&$code({x => {}}, {}, {}), '');
    is(&$code({x => []}, {}, {}), '');
    is(&$code({x => [0]}, {}, {}), '');
    is(&$code({x => {a => 2}}, {}, {}), '');

    # Calls
    $code = compile('foo()');
    is(&$code({}, {}, {foo => sub { 10 }}), 10);
    $code = compile('foo() + 5');
    is(&$code({}, {}, {foo => sub { 10 }}), 15);
    $code = compile('foo(4)');
    is(&$code({}, {}, {foo => sub { $_[0] * 10 }}), 40);
    $code = compile('foo(8, 4)');
    is(&$code({}, {}, {foo => sub { $_[0] / $_[1] }}), 2);
    $code = compile('foo("a")');
    is(&$code({}, {}, {foo => sub { $_[0] . 'b' }}), 'ab');
    $code = compile('foo(i)');
    is(&$code({i => 3}, {}, {foo => sub { $_[0] + 2 }}), 5);
    $code = compile('foo(2, :i => 3, :j => 5)');
    is(&$code({}, {}, {foo => sub { join(':', @_) }}), '2:i:3:j:5');
    $code = compile('foo()');
    eval { &$code({}, {}, {}) };
    like($@, qr/unknown function 'foo'/i);

    # Blocks
    $code = compile('f() do', '"abc"', 'end');
    no_warnings { is(&$code({}, {}, {f => sub { }}), '') };
    is(&$code({}, {}, {f => sub { 'x' }}), 'x');
    $code = compile('f() do', '"abc"', 'end');
    is(&$code({}, {}, {f => sub { &{$_[0]} . 'xyz' }}), 'abcxyz');
    $code = compile('f() do', '"abc"', 'end');
    is(&$code({}, {}, {f => sub { &{$_[0]} . &{$_[0]} }}), 'abcabc');
    $code = compile('f(40) do', '2', 'end');
    is(&$code({}, {}, {f => sub { $_[0] + &{$_[1]} }}), '42');

    # For
    $code = compile('for x in y', 'x', 'end');
    is(&$code({}, {}, {}), '');
    is(&$code({y => [10, 20, 30]}, {}, {}), '102030');
    $code = compile('for x in @y', 'x', 'end');
    is(&$code({}, {y => [2, 3, 5]}, {}), '235');
    $code = compile('for x, y in p', 'x - y', 'end');
    is(&$code({p => [[6, 2], [3, 1]]}, {}, {}), '42');

    # if/elsif/else
    $code = compile('if 42', '1', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 0', '1', 'elsif 42', '2', 'end');
    is(&$code({}, {}, {}), 2);
    $code = compile('if 0', '1', 'elsif 0', '2', 'end');
    is(&$code({}, {}, {}), '');
    $code = compile('if 0', '1', 'elsif "abc"', '2', 'end');
    is(&$code({}, {}, {}), 2);
    $code = compile('if 0', '1', 'else', '2', 'end');
    is(&$code({}, {}, {}), 2);
    eval { compile('if 0', '1', 'elseif 1', '2', 'end') };
    like($@, qr/invalid syntax/i);

    # Conditional expressions
    $code = compile('"a" if 1');
    is(&$code({}, {}, {}), 'a');
    $code = compile('"a" if 0');
    is(&$code({}, {}, {}), '');
    eval { compile('"a" elsif 1') };
    like($@, qr/invalid syntax/i);
    eval { compile('"a" :if 1') };
    like($@, qr/invalid syntax/i);

    # and/or
    $code = compile('if 0 or 42', '1', 'end');
    is(&$code({}, {}, {}), '1');
    $code = compile('if 42 or 0', '1', 'end');
    is(&$code({}, {}, {}), '1');
    $code = compile('if 0 and 42', '1', 'end');
    is(&$code({}, {}, {}), '');
    $code = compile('if 42 and 0', '1', 'end');
    is(&$code({}, {}, {}), '');
    $code = compile('if 0 or !1', '1', 'end');
    is(&$code({}, {}, {}), '');

    # Numeric comparisons
    $code = compile('if 1 > 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if 3 > 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 1 >= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if 2 >= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 3 >= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 1 < 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 3 < 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if 1 <= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 2 <= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 3 <= 2', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if 1 == 0', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if 1 == 1', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 1 != 0', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if 1 != 1', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);

    # String comparisons
    $code = compile('if "foo" == "foo"', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
    $code = compile('if "foo" == "bar"', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if "foo" != "foo"', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 0);
    $code = compile('if "foo" != "bar"', '1', 'else', '0', 'end');
    is(&$code({}, {}, {}), 1);
}


# Template application
{
    my ($code, $ns, $data);

    $code = template('x');
    is(&$code({}, {}, {}), 'x');

    $code = template('');
    is(&$code({}, {}, {}), '');
    $code = template('<% %>');
    is(&$code({}, {}, {}), '');
    $code = template('<%= %>');
    is(&$code({}, {}, {}), '');
    $code = template('<%= # "hello" %>');
    is(&$code({}, {}, {}), '');
    $code = template('<%= # "hello %>');
    is(&$code({}, {}, {}), '');
    $code = template('<%= # "hello %>x<%= "y" %>');
    is(&$code({}, {}, {}), 'xy');
    $code = template('<%= "x" # "hello %>y %>');
    is(&$code({}, {}, {}), 'xy %>');
    $code = template('<%# "hello %>x %>');
    is(&$code({}, {}, {}), 'x %>');

    $code = template('a');
    is(&$code({}, {}, {}), 'a');
    $code = template('a<% 1 %>');
    is(&$code({}, {}, {}), 'a');
    $code = template('a<%= 1 %>');
    is(&$code({}, {}, {}), 'a1');
    $code = template('a<% 1 %>b');
    is(&$code({}, {}, {}), 'ab');
    $code = template('a<%= 1 %>b');
    is(&$code({}, {}, {}), 'a1b');

    $code = template('<%= x + 1 %>');
    is(&$code({x => 4}, {}, {}), '5');
    $code = template('<%= x # + 1 %>');
    is(&$code({x => 4}, {}, {}), '4');
    $code = template('<% x + 1 %>');
    is(&$code({x => 4}, {}, {}), '');

    $code = template('<%= "%>" %>');
    is(&$code({}, {}, {}), '%&gt;');
    $code = template('a<%= "%>" %>b');
    is(&$code({}, {}, {}), 'a%&gt;b');
    $code = template('<"<%= x %>">');
    is(&$code({x => 1}, {}, {}), '<"1">');
    no_warnings { is(&$code({}, {}, {}), '<"">') };
    $code = template('"<%= "a" %>"<%= 1 %>');
    is(&$code({}, {}, {}), '"a"1');

    $code = template('<%= x %>');
    is(&$code({x => 'a&<b>'}, {}, {}), 'a&amp;&lt;b&gt;');
    is(&$code({x => "\xc2\x80"}, {}, {}), '&#128;');
    is(&$code({x => "\xe2\x80\x93"}, {}, {}), '&#8211;');

    $code = template('<%= x(10) %>');
    is(&$code({}, {}, {x => sub { $_[0] * 2 }}), '20');
    eval { &$code({}, {}, {}) };
    like($@, qr/unknown function 'x'/i);

    $code = template('a<% for x in l %><%= x %><% end %>b');
    is(&$code({l => [1, 2, 3]}, {}, {}), 'a123b');
    is(&$code({l => undef}, {}, {}), 'ab');

    $code = template('a<% if x %>b<% end %>c');
    is(&$code({x => 1}, {}, {}), 'abc');
    is(&$code({x => 0}, {}, {}), 'ac');
    is(&$code({}, {}, {}), 'ac');

    eval { template("x\n<% foo\ny\n", 'name') };
    like($@, qr/missing %> .*in 'name' at line 2/i);
    eval { template("x\n<% ^ %>\ny\n", 'blah') };
    like($@, qr/invalid syntax .*in 'blah' at line 2/i);
    eval { template("x\n<% for %>\ny\n", 'xyz') };
    like($@, qr/expected variable .*in 'xyz' at line 2/i);
    eval { template("x\n<% for x %>\ny\n", 'abc') };
    like($@, qr/expected 'in' .*in 'abc' at line 2/i);
    eval { template("x\n<% for x %>\ny\n") };
    like($@, qr/expected 'in'.* at line 2/i);
    eval { template("x\ny\n<% end %>\nz\n") };
    like($@, qr/unexpected 'end' .*at line 3/i);
    eval { template("x\ny\n<% else %>\nz\n") };
    like($@, qr/unexpected 'else' .*at line 3/i);
    eval { template("x\n<% if 1 %>") };
    like($@, qr/unclosed 'if' .*at line 2/i);
    eval { template("x\n<% if 1 %>\ny\nz\n", 'foo') };
    like($@, qr/unclosed 'if' .*in 'foo' at line 2/i);
    eval { template("x\n<% ! %>\ny\n", 'blah') };
    like($@, qr/missing or invalid expression .*in 'blah' at line 2/i);
    eval { template("x\n<% (1 + 2 %>\ny\n", 'x') };
    like($@, qr/missing \) .*in 'x' at line 2/i);
    eval { template("x\n<% x. %>\ny\n", 'abc') };
    like($@, qr/missing attribute .*in 'abc' at line 2/i);
    eval { template("x\n<% x(1 %>\ny\n", '123') };
    like($@, qr/missing \) .*in '123' at line 2/i);
    eval { template("x\n<% ) %>\ny\n", 'foo') };
    like($@, qr/missing or invalid expression .*in 'foo' at line 2/i);
    eval { template("<% f() do %>a", 'blocky') };
    like($@, qr/unclosed 'do' .*in 'blocky' at line 1/i);

    $code = template("x\n<%= 1 %>\n<% error() %>");
    eval { &$code({}, {}, {error => sub { die 'blah' }}) };
    like($@, qr/.* at line 3/i);
    $code = template("\n\n\n<%= 2 / n %>");
    eval { &$code({n => 0}, {}, {}) };
    like($@, qr/division by zero.* at line 4/si);
    $code = template("\n<%= x.y %>\n", 'test');
    eval { &$code({x => 1}, {}, {}) };
    like($@, qr/can't call method "y" .*in 'test' at line 2/si);

    $code = template("<% if 1 %>\nx\ny\n<% end %>");
    is(&$code(), "x\ny\n");
    $code = template("<% if 1 %>\nx\ny\n<% end %>\n");
    is(&$code(), "x\ny\n");
    $code = template("x<% if 1 %>\ny\n<% end %>");
    is(&$code(), "x\ny\n");
    $code = template("<% if 1 %>  \nx\ny\n<% end %>\n");
    is(&$code(), "x\ny\n");
    $code = template(" <% if 1 %>\nx\ny\n<% end %>\n");
    is(&$code(), "x\ny\n");
    $code = template("<% if 0 %>\nx\ny\n<% end %>");
    is(&$code(), "");
    $code = template("<% if 0 %>\nx\ny\n<% end %>\n");
    is(&$code(), "");
    $code = template("<% if 1 %>\nx\ny\n<% end %>\nz");
    is(&$code(), "x\ny\nz");
    $code = template("<% if 1 %>\nx\ny\n<% end %>\nz\n");
    is(&$code(), "x\ny\nz\n");
    $code = template("<% if 0 %>\nx\n<% else %>\ny\n<% end %>");
    is(&$code(), "y\n");

    $code = template("x\r\n\r\ny");
    is(&$code(), "x\n\ny");
    $code = template("x\r\n\r\ny\r\n");
    is(&$code(), "x\n\ny\n");
    $code = template("<% 1 %>\r\nx\r\ny");
    is(&$code(), "x\ny");

    $code = template('a<% x = "$foo" %>b');
    $ns = {};
    is(&$code($ns, {}, {}), 'ab');
    is($ns->{x}, '$foo');
    $code = template('a<% @x = "$foo" %>b');
    $ns = {};
    is(&$code({}, $ns, {}), 'ab');
    is($ns->{x}, '$foo');

    $code = template('<% collect() do %>abc<% end %>');
    is(&$code({}, {}, {collect => sub { $data = &{$_[0]} }}), '');
    is($data, 'abc');
}

# Perl warnings become template errors
{
    my ($code);

    $code = template("abc\n<% v.size %>", 'boom1');
    eval { &$code({v => undef}, {}, {}) };
    like($@, qr/uninitialized value.*at boom1 line 2/i);

    $code = template('<% v.size %>', 'boom2');
    eval { &$code({v => undef}, {}, {}) };
    like($@, qr/uninitialized value.*at boom2 line 1/i);
}
