#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 209;

use Pinwheel::View::ERB;


sub get_tokens
{
    my $lexer = Pinwheel::View::ERB::lexer(shift);
    my ($t, @tokens);
    while ($t = $lexer->()) {
        last if $t->[0] eq '';
        push @tokens, $t;
    }
    return \@tokens;
}

sub parse
{
    my $s = shift;
    my $writer = (@_ > 0) ? shift : Pinwheel::View::ERB::code_writer('test');
    my $lexer = Pinwheel::View::ERB::lexer($s);
    return Pinwheel::View::ERB::parse_code($lexer, $writer);
}


# Lexer
{
    my ($tokens, $lexer);

    # Numbers
    $tokens = get_tokens('1');
    is_deeply($tokens, [['NUM', 1]]);
    $tokens = get_tokens('1234');
    is_deeply($tokens, [['NUM', 1234]]);
    $tokens = get_tokens('  1');
    is_deeply($tokens, [['NUM', 1]]);
    $tokens = get_tokens('1  ');
    is_deeply($tokens, [['NUM', 1]]);
    $tokens = get_tokens('  1  ');
    is_deeply($tokens, [['NUM', 1]]);
    $tokens = get_tokens('-123');
    is_deeply($tokens, [['-', ''], ['NUM', 123]]);

    # Symbols
    $tokens = get_tokens(':x');
    is_deeply($tokens, [['SYM', 'x']]);
    $tokens = get_tokens(':foo_bar');
    is_deeply($tokens, [['SYM', 'foo_bar']]);

    # Keywords
    $tokens = get_tokens('if');
    is_deeply($tokens, [['STMT', 'if']]);
    $tokens = get_tokens('elsif else');
    is_deeply($tokens, [['STMT', 'elsif'], ['STMT', 'else']]);
    $tokens = get_tokens('for in');
    is_deeply($tokens, [['STMT', 'for'], ['in', '']]);
    $tokens = get_tokens('end');
    is_deeply($tokens, [['STMT', 'end']]);
    $tokens = get_tokens('do');
    is_deeply($tokens, [['do', '']]);
    $tokens = get_tokens('elseif');
    is_deeply($tokens, [['ID', 'elseif']]);

    # Variables
    $tokens = get_tokens('format');
    is_deeply($tokens, [['ID', 'format']]);
    $tokens = get_tokens('foo');
    is_deeply($tokens, [['ID', 'foo']]);
    $tokens = get_tokens('foo_bar');
    is_deeply($tokens, [['ID', 'foo_bar']]);
    $tokens = get_tokens('foo123');
    is_deeply($tokens, [['ID', 'foo123']]);
    $tokens = get_tokens('@foo');
    is_deeply($tokens, [['@ID', 'foo']]);
    $tokens = get_tokens('iffy elsiff elsen');
    is_deeply($tokens, [['ID', 'iffy'], ['ID', 'elsiff'], ['ID', 'elsen']]);
    $tokens = get_tokens('ford ender');
    is_deeply($tokens, [['ID', 'ford'], ['ID', 'ender']]);
    $tokens = get_tokens('done inner');
    is_deeply($tokens, [['ID', 'done'], ['ID', 'inner']]);
    $tokens = get_tokens('orbit andy');
    is_deeply($tokens, [['ID', 'orbit'], ['ID', 'andy']]);

    # Dots, commas, =>
    $tokens = get_tokens('foo.bar');
    is_deeply($tokens, [['ID', 'foo'], ['.', ''], ['ID', 'bar']]);
    $tokens = get_tokens('@foo.bar');
    is_deeply($tokens, [['@ID', 'foo'], ['.', ''], ['ID', 'bar']]);
    $tokens = get_tokens('foo,bar');
    is_deeply($tokens, [['ID', 'foo'], [',', ''], ['ID', 'bar']]);
    $tokens = get_tokens('foo,123');
    is_deeply($tokens, [['ID', 'foo'], [',', ''], ['NUM', 123]]);
    $tokens = get_tokens('foo , 123');
    is_deeply($tokens, [['ID', 'foo'], [',', ''], ['NUM', 123]]);
    $tokens = get_tokens(':x => y');
    is_deeply($tokens, [['SYM', 'x'], ['=>', ''], ['ID', 'y']]);

    # Strings
    $tokens = get_tokens('"a, 2 + 3, blah"');
    is_deeply($tokens, [['STR', 'a, 2 + 3, blah']]);
    $tokens = get_tokens('"x\'y"');
    is_deeply($tokens, [['STR', 'x\'y']]);
    $tokens = get_tokens("'x\"y'");
    is_deeply($tokens, [['STR', 'x"y']]);

    # Operators
    $tokens = get_tokens('=+-');
    is_deeply($tokens, [['=', ''], ['+', ''], ['-', '']]);
    $tokens = get_tokens('*/%');
    is_deeply($tokens, [['*', ''], ['/', ''], ['%', '']]);

    # or, and
    $tokens = get_tokens('or and');
    is_deeply($tokens, [['or', ''], ['and', '']]);
    $tokens = get_tokens('|| &&');
    is_deeply($tokens, [['or', ''], ['and', '']]);

    # Comparisons
    $tokens = get_tokens('== != <= >=');
    is_deeply($tokens, [['==', ''], ['!=', ''], ['<=', ''], ['>=', '']]);
    $tokens = get_tokens('< > !');
    is_deeply($tokens, [['<', ''], ['>', ''], ['!', '']]);

    # Parentheses
    $tokens = get_tokens('(()');
    is_deeply($tokens, [['(', ''], ['(', ''], [')', '']]);

    # Comments
    $tokens = get_tokens('#xyz');
    is_deeply($tokens, []);
    $tokens = get_tokens('# abc def ghi');
    is_deeply($tokens, []);
    $tokens = get_tokens('1 # foo');
    is_deeply($tokens, [['NUM', '1']]);
    $tokens = get_tokens('#xyz"def');
    is_deeply($tokens, []);
    $tokens = get_tokens("#xyz'def");
    is_deeply($tokens, []);

    # Combinations
    $tokens = get_tokens('1+2');
    is_deeply($tokens, [['NUM', '1'], ['+', ''], ['NUM', '2']]);
    $tokens = get_tokens('(1+2)*3');
    is_deeply($tokens, [
        ['(', ''], ['NUM', '1'], ['+', ''], ['NUM', '2'], [')', ''],
        ['*', ''], ['NUM', '3']
    ]);
    $tokens = get_tokens('f() do');
    is_deeply($tokens, [['ID', 'f'], ['(', ''], [')', ''], ['do', '']]);

    # Peek
    $lexer = Pinwheel::View::ERB::lexer('1 2 3');
    is_deeply($lexer->(1), ['NUM', 1]);
    is_deeply($lexer->(2), ['NUM', 2]);
    is_deeply($lexer->(1), ['NUM', 1]);
    is_deeply($lexer->(), ['NUM', 1]);
    is_deeply($lexer->(), ['NUM', 2]);
    is_deeply($lexer->(1), ['NUM', 3]);
    is_deeply($lexer->(2), ['', '']);
    is_deeply($lexer->(), ['NUM', 3]);
    is_deeply($lexer->(1), ['', '']);
    is_deeply($lexer->(), ['', '']);
    is_deeply($lexer->(1), ['', '']);

    # Invalid syntax
    $lexer = Pinwheel::View::ERB::lexer('^');
    is_deeply($lexer->(), ['', '^']);
    $lexer = Pinwheel::View::ERB::lexer('^ blah blah');
    is_deeply($lexer->(), ['', '^ blah blah']);
}


# Parser
{
    my $writer;

    # Empty
    is(parse(''), '');
    is(parse('  '), '');
    is(parse('# 1'), '');

    # Simple tokens
    is(parse('1'), '1');
    is(parse('"a string"'), '$strings->[0]');
    is(parse('"a $string"'), '$strings->[0]');
    is(parse("'a string'"), '$strings->[0]');
    is(parse('a_variable'), '$locals->{\'a_variable\'}');

    # Numbers
    is(parse('1'), '1');
    is(parse('-1'), '-1');
    is(parse('- 1'), '-1');
    is(parse('1 + 2'), '_add(1, 2)');
    is(parse('1 - 2'), '(1 - 2)');
    is(parse('1 * 2'), '(1 * 2)');
    is(parse('1 / 2'), '(1 / 2)');
    is(parse('1 % 2'), '(1 % 2)');
    is(parse('1 + 2 + 3'), '_add(_add(1, 2), 3)');
    is(parse('1 + 2 - 3'), '(_add(1, 2) - 3)');
    is(parse('1 * 2 * 3'), '((1 * 2) * 3)');
    is(parse('1 + 2 * 3'), '_add(1, (2 * 3))');
    is(parse('(1 + 2) * 3'), '(_add(1, 2) * 3)');
    is(parse('10 + -4'), '_add(10, -4)');
    is(parse('10 - -4'), '(10 - -4)');
    is(parse('2 * -3 + 1'), '_add((2 * -3), 1)');
    is(parse('-x'), '-$locals->{\'x\'}');
    is(parse('-x + 10'), '_add(-$locals->{\'x\'}, 10)');
    is(parse('-(1 + 2)'), '-_add(1, 2)');

    # Strings
    is(parse('"foo"'), '$strings->[0]');
    is(parse("'foo'"), '$strings->[0]');
    is(parse("'foo' + 2"), '_add($strings->[0], 2)');
    is(parse('"foo" + "foo"'), '_add($strings->[0], $strings->[0])');
    is(parse('"foo" + \'foo\''), '_add($strings->[0], $strings->[0])');
    is(parse('"foo" + "bar"'), '_add($strings->[0], $strings->[1])');

    # Symbols
    is(parse(':foo'), '$strings->[0]');
    eval { parse(':123') };
    like($@, qr/invalid syntax/i);

    # Attributes
    is(parse('foo.bar'), "_getattr(\$locals->{'foo'}, 'bar')");
    is(parse('foo.end'), "_getattr(\$locals->{'foo'}, 'end')");
    is(parse('foo.bar.baz'), "_getattr(\$locals->{'foo'}, 'bar', 'baz')");
    is(parse('foo.size'), "_getattr_slow(\$locals->{'foo'}, 'size')");
    is(parse('foo.x.size'), "_getattr_slow(\$locals->{'foo'}, 'x', 'size')");
    is(parse('@foo.bar'), "_getattr(\$globals->{'foo'}, 'bar')");
    is(parse('@x.y.z'), "_getattr(\$globals->{'x'}, 'y', 'z')");
    eval { parse('x.') };
    like($@, qr/missing attribute/i);
    eval { parse('x.1') };
    like($@, qr/missing attribute/i);
    eval { parse('@x.@y') };
    like($@, qr/missing attribute/i);

    # Parentheses
    is(parse('(1)'), '1');
    is(parse('(((1)))'), '1');
    is(parse('(1-2)-3'), '((1 - 2) - 3)');
    is(parse('1-(2-3)'), '(1 - (2 - 3))');
    is(parse('1-((2-3))'), '(1 - (2 - 3))');
    eval { parse('(') };
    like($@, qr/missing or invalid/i);
    eval { parse('(1()') };
    like($@, qr/missing \)/i);

    # Variables
    is(parse('foo'), "\$locals->{'foo'}");
    is(parse('@foo'), "\$globals->{'foo'}");
    is(parse('foo + bar'), "_add(\$locals->{'foo'}, \$locals->{'bar'})");
    is(parse('foo + @bar'), "_add(\$locals->{'foo'}, \$globals->{'bar'})");

    # Hashes
    is(parse("{}"), "{}");
    is(parse('{ :foo => :bar }'), "{'foo' => \$strings->[0], }");
    is(parse('{ :foo => @bar }'), "{'foo' => \$globals->{'bar'}, }");
    is(parse('{ :foo => :bar, :rat => 8 }'), "{'foo' => \$strings->[0], 'rat' => 8, }");

    # Arrays
    is(parse("[]"), "[]");
    is(parse('[ :foo ]'), "[\$strings->[0], ]");
    is(parse('[ "foo" ]'), "[\$strings->[0], ]");
    is(parse('[ 1+2 ]'), "[_add(1, 2), ]");
    is(parse('[ :foo, :bar ]'), "[\$strings->[0], \$strings->[1], ]");
    is(parse('[ 1, 2, 3 ]'), "[1, 2, 3, ]");
    eval { parse('[1,2,3') };
    like($@, qr/Missing \]/i);
    eval { parse('1,2,3]') };
    like($@, qr/Invalid syntax/i);
    eval { parse('[,]') };
    like($@, qr/missing or invalid expression/i);

    # Function calls
    is(parse('foo()'), "\$fns->{'foo'}->()");
    is(parse('foo(1)'), "\$fns->{'foo'}->(1)");
    is(parse('foo(1, 2, 3)'), "\$fns->{'foo'}->(1, 2, 3)");
    is(parse('foo("bar")'), "\$fns->{'foo'}->(\$strings->[0])");
    is(parse('foo(x)'), "\$fns->{'foo'}->(\$locals->{'x'})");
    is(parse('foo(@x)'), "\$fns->{'foo'}->(\$globals->{'x'})");
    is(parse('foo(:n => 5)'), "\$fns->{'foo'}->('n', 5)");
    is(parse('foo(:x, 1)'), "\$fns->{'foo'}->(\$strings->[0], 1)");
    is(parse('foo(1, :n => 5)'), "\$fns->{'foo'}->(1, 'n', 5)");
    is(parse('foo(@x, :n => 5)'), "\$fns->{'foo'}->(\$globals->{'x'}, 'n', 5)");
    is(parse('foo(:a => 8, :b => 9)'), "\$fns->{'foo'}->('a', 8, 'b', 9)");
    eval { parse('foo(, 10)') };
    like($@, qr/missing or invalid expression/i);
    eval { parse('foo(10 (') };
    like($@, qr/missing \)/i);
    eval { parse('foo(10 !') };
    like($@, qr/missing \)/i);
    eval { parse('foo(10') };
    like($@, qr/missing \)/i);
    eval { parse('foo(x => 1)') };
    like($@, qr/missing \)/i);
    eval { parse('foo(:x =>)') };
    like($@, qr/missing or invalid expression/i);

    # Blocks
    is(parse('f() do'), "\$fns->{'f'}->(sub { my \$r = \$r->clone([])");
    is(parse('f(1) do'), "\$fns->{'f'}->(1, sub { my \$r = \$r->clone([])");
    is(parse('f(1, 9) do'), "\$fns->{'f'}->(1, 9, sub { my \$r = \$r->clone([])");
    $writer = Pinwheel::View::ERB::code_writer('test');
    parse('f() do', $writer);
    is(parse('end', $writer), '$r->to_string(); })');
    eval { parse('f() do 1') };
    like($@, qr/invalid syntax/i);
    eval { parse('f(g() do)') };
    like($@, qr/invalid syntax/i);

    # Negation
    is(parse('!1'), '!(1)');
    is(parse('! 1'), '!(1)');
    is(parse('!!1'), '!!(1)');
    is(parse('!!!1'), '!(1)');
    is(parse('!(1 + 2)'), '!(_add(1, 2))');
    is(parse('!foo'), '!($locals->{\'foo\'})');
    is(parse('!foo - 1'), '(!($locals->{\'foo\'}) - 1)');
    is(parse('1 - !foo'), '(1 - !($locals->{\'foo\'}))');
    is(parse('!x.y'), "!(_getattr(\$locals->{'x'}, 'y'))");
    is(parse('!foo(9)'), "!(\$fns->{'foo'}->(9))");

    # Assignments
    is(parse('x = 1'), "\$locals->{'x'} = 1");
    is(parse('@x = 1'), "\$globals->{'x'} = 1");
    is(parse('x = 1 + 10'), "\$locals->{'x'} = _add(1, 10)");
    is(parse('@x = 2 * 5'), "\$globals->{'x'} = (2 * 5)");
    is(parse('x = foo(2)'), "\$locals->{'x'} = \$fns->{'foo'}->(2)");
    is(parse('@x = foo(42)'), "\$globals->{'x'} = \$fns->{'foo'}->(42)");
    eval { parse('x = ') };
    like($@, qr/missing or invalid expression/i);

    # Unpacking
    is(parse('x, y = f()'), '@$locals{qw(x y)} = @{$fns->{\'f\'}->()}');
    eval { parse('x, = f()') };
    like($@, qr/expected variable/i);
    eval { parse('x, y z = f()') };
    like($@, qr/expected '='/i);
    eval { parse('@x, y = f()') };
    like($@, qr/invalid syntax/i);

    # For
    is(parse('for x in y'),
        "foreach (\@{\$locals->{'y'}}) { \$locals->{'x'} = \$_;");
    is(parse('for x in @y'),
        "foreach (\@{\$globals->{'y'}}) { \$locals->{'x'} = \$_;");
    is(parse('for x in things()'),
        "foreach (\@{\$fns->{'things'}->()}) { \$locals->{'x'} = \$_;");
    is(parse('for x, y in z'),
        'foreach (@{$locals->{\'z\'}}) { @$locals{qw(x y)} = @$_;');
    $writer = Pinwheel::View::ERB::code_writer('test');
    parse('for x in y', $writer);
    is(parse('end', $writer), '}');
    eval { parse('for 1 in x') };
    like($@, qr/expected variable/i);
    eval { parse('for x') };
    like($@, qr/expected 'in'/i);
    eval { parse('for x y') };
    like($@, qr/expected 'in'/i);
    eval { parse('for x in') };
    like($@, qr/missing or invalid expression/i);
    eval { parse('for x, in y') };
    like($@, qr/expected variable/i);
    eval { parse('for x, 1 in y') };
    like($@, qr/expected variable/i);

    # Conditionals
    is(parse('if 1'), "if (1) {");
    is(parse('if x'), "if (\$locals->{'x'}) {");
    is(parse('if !1'), "if (!(1)) {");
    is(parse('if 1 == 2'), 'if ((1 eq 2)) {');
    is(parse('if 1 == 2 or 3 == 3'), 'if (((1 eq 2) || (3 eq 3))) {');
    is(parse('if 1 or 2'), 'if ((1 || 2)) {');
    is(parse('if 1 and 2'), 'if ((1 && 2)) {');
    is(parse('if 1 and 2 or 3'), 'if (((1 && 2) || 3)) {');
    $writer = Pinwheel::View::ERB::code_writer('test');
    is(parse('if 2', $writer), 'if (2) {');
    is(parse('elsif 4', $writer), '} elsif (4) {');
    is(parse('else', $writer), '} else {');
    is(parse('end', $writer), '}');

    # Invalid syntax
    eval { parse('^') };
    like($@, qr/invalid syntax/i);
    eval { parse('"abc') };
    like($@, qr/invalid syntax/i);
    eval { parse('1 +') };
    like($@, qr/missing or invalid/i);
    eval { parse('1 + (2 * 3') };
    like($@, qr/missing \)/i);
    eval { parse('foo.') };
    like($@, qr/missing attribute/i);
    eval { parse('foo.1') };
    like($@, qr/missing attribute/i);
    eval { parse('foo.+') };
    like($@, qr/missing attribute/i);
    eval { parse('1 + .') };
    like($@, qr/missing or invalid/i);
    eval { parse('foo(1') };
    like($@, qr/missing \)/i);
    eval { parse('elsif 1') };
    like($@, qr/unexpected 'elsif'/i);
    eval { parse('else') };
    like($@, qr/unexpected 'else'/i);
    eval { parse('end') };
    like($@, qr/unexpected 'end'/i);
    $writer = Pinwheel::View::ERB::code_writer('test');
    parse('for x in y', $writer);
    eval { parse('elsif', $writer) };
    like($@, qr/unexpected 'elsif'/i);
}
