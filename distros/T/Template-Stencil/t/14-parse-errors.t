#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub err_like {
    my ($src, $re, $name) = @_;
    eval { Template::Stencil::_inspect($src) };
    like($@, $re, $name);
}

# Every compile error carries <string>:line:col.
err_like('{% if x %}', qr/<string>:1:1: unclosed 'if' block/,
         'unclosed if names opener');
err_like("\n\n  {% for i in x %}", qr/<string>:3:3: unclosed 'for' block/,
         'opener line:col tracked across newlines');
err_like('{% end %}', qr/'end' with no open block/, 'stray end');
err_like('{% else %}', qr/'else' with no open block/, 'stray else');
err_like('{% if a %}{% else %}{% else %}x{% end %}',
         qr/duplicate 'else'/, 'double else');
err_like('{% if a %}{% else %}{% elsif b %}x{% end %}',
         qr/'elsif' after 'else'/, 'elsif after else');
err_like('{% for i in x %}{% else %}{% end %}',
         qr/'else' inside 'for'/, 'else inside for');
err_like('{% unless a %}{% elsif b %}x{% end %}',
         qr/'elsif' inside 'unless'/, 'elsif inside unless');

# Tag-level errors.
err_like('{% name', qr/expected '%\}'/, 'unterminated tag');
err_like('{%# never closed', qr/unterminated comment/, 'unterminated comment');
err_like('{% 9lives %}', qr/expected a name or keyword/, 'bad tag start');

# Expressions.
err_like("{% if a eq 'x %}y{% end %}", qr/unterminated string literal/,
         'unterminated string');
err_like('{% if %}x{% end %}', qr/expected an expression/, 'if without expr');
err_like('{% if (a %}x{% end %}', qr/expected '\)'/, 'unclosed paren');
err_like('{% if a == %}x{% end %}', qr/expected an expression/,
         'dangling comparison');
err_like('{% if defined a %}x{% end %}', qr/defined needs \(path\)/,
         'defined without parens');

# Paths.
err_like('{% a..b %}', qr/expected name after '\.'/, 'double dot');
err_like('{% a[x] %}', qr/expected digits in \[index\]/, 'non-numeric index');
err_like('{% a[1 %}', qr/expected '\]'/, 'unclosed index');

# set.
err_like('{% set a.b = 1 %}', qr/'set' target must be a plain name/,
         'dotted set target');
err_like('{% set a %}', qr/expected '=' after the 'set' name/,
         'set without =');
err_like('{% set for = 1 %}', qr/expected a variable name/,
         'keyword as set name');

# for.
err_like('{% for i x %}{% end %}', qr/expected 'in'/, 'for missing in');
err_like('{% for in in x %}{% end %}', qr/expected a loop variable/,
         'keyword as loop var');

# include.
err_like('{% include %}', qr/expected a template name/, 'include no name');

# filters.
err_like('{% v | %}', qr/expected a filter name/, 'pipe without name');
err_like('{% v | upper(1) %}', qr/filter 'upper' takes no argument/,
         'arity: upper');
err_like('{% v | default %}', qr/filter 'default' needs an argument/,
         'arity: default');

# Depth cap.
{
    my $src = ('{% if a %}' x 65) . 'x' . ('{% end %}' x 65);
    err_like($src, qr/nested deeper than 64/, 'depth 65 rejected');
    my $ok = ('{% if a %}' x 64) . 'x' . ('{% end %}' x 64);
    ok(eval { Template::Stencil::_inspect($ok); 1 }, 'depth 64 fine');
}

# Column accuracy on a mid-line error.
err_like('ab {% if x %}', qr/:1:4: unclosed/, 'column points at the tag');

done_testing;
