#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Sandbox;
use Template::Sandbox::StringFunctions;

plan tests => 5;

my ( $template, $syntax, $expected );

#
#  1:  template toolkit compat
#  Generated as from Template::Benchmark.
$syntax = <<'END_OF_TEMPLATE';
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo

[% scalar_variable %]
[% hash_variable.hash_value_key %]
[% array_variable[ 2 ] %]
[% this.is.a.very.deep.hash.structure %]
[% FOREACH i IN array_loop %][% i %][% END %]
[% FOREACH k IN hash_loop %][% k %]: [% k.__value__ %][% END %]
[% FOREACH r IN records_loop %][% r.name %]: [% r.age %][% END %]
[% IF 1 %]true[% END %]
[% IF variable_if %]true[% END %]
[% IF 1 %]true[% ELSE %]false[% END %]
[% IF variable_if_else %]true[% ELSE %]false[% END %]
[% IF 1 %][% template_if_true %][% END %]
[% IF variable_if %][% template_if_true %][% END %]
[% IF 1 %][% template_if_true %][% ELSE %][% template_if_false %][% END %]
[% IF variable_if_else %][% template_if_true %][% ELSE %][% template_if_false %][% END %]
[% 10 + 12 %]
[% variable_expression_a * variable_expression_b %]
[% ( ( variable_expression_a * variable_expression_b ) + variable_expression_a - variable_expression_b ) / variable_expression_b %]
[% variable_function_arg.substr( 4, 2 ) %]
END_OF_TEMPLATE

$expected = <<'END_OF_EXPECTED';
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo
foo foo foo foo foo foo foo foo foo foo foo foo

I is a scalar, yarr!
I spy with my little eye, something beginning with H.
an
My god, it's full of hashes.
fivefourthreetwoonecomingreadyornot
aaa: firstbbb: secondccc: thirdddd: fourtheee: fifth
Joe Bloggs: 16Fred Bloggs: 23Nigel Bloggs: 43Tarquin Bloggs: 143Geoffrey Bloggs: 13
true
true
true
false
True dat
True dat
True dat
Nay, Mister Wilks
22
200
21
he
END_OF_EXPECTED

$template = Template::Sandbox->new(
    template_toolkit_compat => 1,
    library => [ 'Template::Sandbox::StringFunctions' => qw/substr/ ],
    );
$template->set_template_string( $syntax );

$template->add_vars( {
    scalar_variable => 'I is a scalar, yarr!',
    hash_variable   => {
        'hash_value_key' =>
            'I spy with my little eye, something beginning with H.',
        },
    array_variable   => [ qw/I have an imagination honest/ ],
    this => { is => { a => { very => { deep => { hash => {
        structure => "My god, it's full of hashes.",
        } } } } } },
    template_if_true  => 'True dat',
    template_if_false => 'Nay, Mister Wilks',
    } );
$template->add_vars( {
    array_loop => [ qw/five four three two one coming ready or not/ ],
    hash_loop  => {
        aaa => 'first',
        bbb => 'second',
        ccc => 'third',
        ddd => 'fourth',
        eee => 'fifth',
        },
    records_loop => [
        { name => 'Joe Bloggs',      age => 16,  },
        { name => 'Fred Bloggs',     age => 23,  },
        { name => 'Nigel Bloggs',    age => 43,  },
        { name => 'Tarquin Bloggs',  age => 143, },
        { name => 'Geoffrey Bloggs', age => 13,  },
        ],
    variable_if      => 1,
    variable_if_else => 0,
    variable_expression_a => 20,
    variable_expression_b => 10,
    variable_function_arg => 'Hi there',
    } );

is( ${$template->run()}, $expected,
    'template toolkit compat' );

my %option_values = (
    open_delimiter  => '<*',
    close_delimiter => '*>',
    allow_bare_expr => 0,
    vmethods        => 0,
    );

#
#  2-5: Check manually supplied options aren't overwritten.
foreach my $option
    ( qw/open_delimiter close_delimiter allow_bare_expr vmethods/ )
{
    $template = Template::Sandbox->new(
        template_toolkit_compat => 1,
        $option                 => $option_values{ $option },
        );
    is( $template->{ $option }, $option_values{ $option },
        "manual $option option overrides template_toolkit_compat" );
}
