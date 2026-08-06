#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

sub ops { [ map $_->{op}, @{ Template::Stencil::_inspect($_[0])->{ops} } ] }
sub op1 { Template::Stencil::_inspect($_[0])->{ops} }

# Empty input compiles to just SOP_END.
is_deeply(ops(''), ['SOP_END'], 'empty template');

# Pure literal.
{
    my $o = op1('hello');
    is_deeply([ map $_->{op}, @$o ],
              ['SOP_LITERAL_SHORT', 'SOP_END'], 'pure literal shape');
    is($o->[0]{bytes}, 'hello', 'literal bytes');
    is($o->[0]{len}, 5, 'literal length');
}

# Stray '}'/'%}' and a lone '{' are plain literal text.
{
    my $o = op1('a } b %} c { d');
    is_deeply([ map $_->{op}, @$o ],
              ['SOP_LITERAL_SHORT', 'SOP_END'], 'stray closers literal');
    is($o->[0]{bytes}, 'a } b %} c { d', 'stray closer bytes');
}

# The {%%} escape emits a literal '{%' merged with its neighbours.
{
    my $o = op1('a{%%}b');
    is_deeply([ map $_->{op}, @$o ],
              ['SOP_LITERAL_SHORT', 'SOP_END'], 'escape merges');
    is($o->[0]{bytes}, 'a{%b', 'escape bytes');
}

# Comments are discarded at compile time and the runs merge. A comment
# may contain '{%' but ends at the first '%}'.
{
    my $o = op1("a{%# strip {% this out %}b");
    is($o->[0]{bytes}, 'ab', 'comment discarded, literals merged');
}
{
    my $o = op1("a{%# multi\nline\ncomment %}b");
    is($o->[0]{bytes}, 'ab', 'multi-line comment discarded');
}

done_testing;
