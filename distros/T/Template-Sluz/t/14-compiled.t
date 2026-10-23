#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

# -------------------------------------------------------------------
# The {foreach} body is compiled into a specialized renderer the first
# time a template is rendered.  These tests make sure the compiled
# renderer produces exactly the same output as the interpreter that is
# used when compilation is unavailable.
# -------------------------------------------------------------------

my $sluz = setup_sluz();

# Force the interpreter path for the reference output
my $orig = \&Template::Sluz::_compile_foreach;
{
    no warnings 'redefine';
    no strict 'refs';
    *Template::Sluz::_compile_foreach = sub { return undef };
}

sub interpret {
    my ($s, $tpl) = @_;
    return eval { $s->parse_string($tpl) } || "ERROR: $@";
}

sub compiled {
    my ($s, $tpl) = @_;
    no warnings 'redefine';
    no strict 'refs';
    *Template::Sluz::_compile_foreach = $orig;
    my $out = eval { $s->parse_string($tpl) } || "ERROR: $@";
    *Template::Sluz::_compile_foreach = sub { return undef };
    return $out;
}

my @templates = (
    '{foreach $array as $x}{$x}{/foreach}',
    '{foreach $array as $i => $x}{$i}{$x}{/foreach}',
    '{foreach $members as $m}{$m.first}{/foreach}',
    '{foreach $members as $i => $m}{$i}:{$m.first} {/foreach}',
    '{foreach $subarr.one as $id}{$id}{/foreach}',
    '{foreach $empty as $x}one{/foreach}',
    '{foreach $array as $x}{if $x}{$x}{/if}{/foreach}',
    '{foreach $array as $x}{$x}{if $__FOREACH_FIRST}F{/if}{/foreach}',
    '{foreach $array as $x}{$x}{if $__FOREACH_LAST}L{/if}{/foreach}',
    '{foreach $array as $x}{$__FOREACH_INDEX}:{$x}{/foreach}',
    '{foreach $arrayd as $row}{foreach $row as $c}{$c}{/foreach}-{/foreach}',
    '{foreach $members as $m}{if $m.first eq "Scott"}S{else}O{/if}{/foreach}',
    '{foreach $members as $m}{if $m.first eq "Scott"}S{elseif $m.first eq "Jason"}J{else}O{/if}{/foreach}',
    '{foreach $members as $m}{if $m.first eq "Scott"}{if $m.last eq "Baker"}SB{else}SX{/if}{else}O{/if}{/foreach}',
    '{foreach $members as $m}{$m.first|uc}:{$m.last|uc} {/foreach}',
    '{foreach $array as $x}{$x|count}{/foreach}',
    '{foreach $array as $x}{$x}{/foreach}{$x}',
    '{foreach $array as $x}{foreach $array as $y}{$x}{$y} {/foreach}{/foreach}',
    '{foreach $colors as $k => $v}{$k}={$v} {/foreach}',
    'BEFORE{foreach $empty as $x}{$x}{/foreach}AFTER',
    '{foreach $array as $x}{* comment *}{$x}{/foreach}',
    '{foreach $array as $x}{literal}{$x}{/literal}{/foreach}',
);

foreach my $tpl (@templates) {
    my $want = interpret($sluz, $tpl);
    my $got  = compiled($sluz, $tpl);
    is($got, $want, "Compiled renderer matches interpreter: $tpl");
}

# -------------------------------------------------------------------
# Compiled renderer honours auto_escape
# -------------------------------------------------------------------
{
    my $esc = Template::Sluz->new(auto_escape => 1);
    $esc->assign(html => '<b>&"x\'</b>');
    $esc->assign(list => ['<a>', '<b>']);

    {
        no warnings 'redefine';
        no strict 'refs';
        *Template::Sluz::_compile_foreach = $orig;
    }

    is($esc->parse_string('{$html}'), '&lt;b&gt;&amp;&quot;x&#x27;&lt;/b&gt;',
        'Auto-escape applies to simple variables');
    is($esc->parse_string('{foreach $list as $l}{$l}{/foreach}'),
       '&lt;a&gt;&lt;b&gt;',
       'Auto-escape applies inside a compiled foreach');
    is($esc->parse_string('{foreach $list as $l}{$l|noescape}{/foreach}'),
       '<a><b>',
       'noescape modifier wins inside a compiled foreach');
}

# -------------------------------------------------------------------
# The compiled renderer is reused across renders and stays correct
# when the template variables change between renders.
# -------------------------------------------------------------------
{
    my $s = setup_sluz();

    {
        no warnings 'redefine';
        no strict 'refs';
        *Template::Sluz::_compile_foreach = $orig;
    }

    my $tpl = '{foreach $array as $x}{$x}{/foreach}';
    is($s->parse_string($tpl), 'onetwothree', 'First render of a compiled foreach');

    $s->assign(array => ['a', 'b']);
    is($s->parse_string($tpl), 'ab', 'Re-render picks up new variable values');

    $s->assign(array => []);
    is($s->parse_string($tpl), '', 'Re-render with an empty list');

    $s->assign(array => ['x']);
    is($s->parse_string($tpl), 'x', 'Re-render with a single element');
}

# -------------------------------------------------------------------
# The compiled renderer must not leak warnings that the interpreter
# suppresses (numeric comparisons of non-numeric values).
# -------------------------------------------------------------------
{
    my $s = setup_sluz();

    {
        no warnings 'redefine';
        no strict 'refs';
        *Template::Sluz::_compile_foreach = $orig;
    }

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $s->parse_string('{foreach $array as $x}{if $x == 5}five{/if}{/foreach}');
    $s->parse_string('{foreach $members as $m}{if $m.first == "Scott"}S{/if}{/foreach}');
    $s->parse_string('{foreach $members as $m}{if $m.last eq "Baker"}B{/if}{/foreach}');

    is(scalar @warnings, 0, 'Compiled renderer emits no warnings')
        or diag("warnings: @warnings");
}

done_testing();
