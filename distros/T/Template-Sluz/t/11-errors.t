#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;

use Test::More;
use FindBin;
require "$FindBin::Bin/test_setup.pl";

# -------------------------------------------------------------------
# Error-code coverage — every _error_out path in the module.
# Codes already exercised elsewhere: #18956, #45821, #73467, #18933
# -------------------------------------------------------------------

# set_delimiters validation (errors #51234 / #51235 / #51236)
{
    my $s = Template::Sluz->new();
    eval { $s->set_delimiters() };
    like($@, qr/#51234/, 'Err #51234 - set_delimiters missing args');

    eval { $s->set_delimiters('<') };
    like($@, qr/#51234/, 'Err #51234 - set_delimiters single arg');

    eval { $s->set_delimiters('<<', '>') };
    like($@, qr/#51235/, 'Err #51235 - delimiter longer than one char');

    eval { $s->set_delimiters('<', '<') };
    like($@, qr/#51236/, 'Err #51236 - open/close delimiters identical');
}

# #86801 - empty template file name to fetch()
{
    my $s = Template::Sluz->new();
    eval { $s->fetch('') };
    like($@, qr/#86801/, 'Err #86801 - empty template filename');
}

# #42280 - unreadable template file to fetch()
{
    my $s = Template::Sluz->new();
    $s->{perl_file_dir} = "$FindBin::Bin";
    # Pin perl_file so fetch() does not recompute perl_file_dir from caller
    $s->{perl_file} = "$FindBin::Bin/01-main.t";
    eval { $s->fetch('no_such_template.stpl') };
    like($@, qr/#42280/, 'Err #42280 - template file cannot be loaded');
}

# #48724 - unterminated comment
{
    my $s = setup_sluz();
    eval { $s->parse_string('{* unterminated comment ') };
    like($@, qr/#48724/, 'Err #48724 - missing closing comment tag');
}

# #47204 - unknown modifier function
{
    my $s = setup_sluz();
    eval { $s->parse_string('{$first|bogus_modifier_xyz}') };
    like($@, qr/#47204/, 'Err #47204 - unknown modifier function');
}

# #31558 - unquoted non-numeric modifier parameter
{
    my $s = setup_sluz();
    eval { $s->parse_string('{$first|join_comma:abc}') };
    like($@, qr/#31558/, 'Err #31558 - bare word modifier param');

    eval { $s->parse_string('{$first|join_comma:;}') };
    like($@, qr/#31558/, 'Err #31558 - punctuation modifier param');
}

# #79134 - exception thrown inside a modifier
{
    my $s = setup_sluz();
    no strict 'refs';
    *{'main::sluz_die'} = sub { die "boom from modifier" };
    eval { $s->parse_string('{$first|sluz_die}') };
    like($@, qr/#79134/, 'Err #79134 - exception inside modifier eval');
}

# #18485 - include target file missing
{
    my $s = setup_sluz();
    eval { $s->parse_string("{include file='no_such_include.stpl'}") };
    like($@, qr/#18485/, 'Err #18485 - include template cannot be loaded');
}

# #68493 - include block with no resolvable file
{
    my $s = setup_sluz();
    eval { $s->parse_string("{include foo='bar'}") };
    like($@, qr/#68493/, 'Err #68493 - no file found in include block');
}

# #50981 - whitespace immediately inside a tag delimiter (any side)
{
    my $s = setup_sluz();

    eval { $s->parse_string('{ $foo}') };
    like($@, qr/#50981/, 'Err #50981 - whitespace after open delimiter');

    eval { $s->parse_string('{$foo }') };
    like($@, qr/#50981/, 'Err #50981 - whitespace before close delimiter');

    eval { $s->parse_string('{ $foo }') };
    like($@, qr/#50981/, 'Err #50981 - whitespace on BOTH sides is an error');

    eval { $s->parse_string('{ $foo|upper}') };
    like($@, qr/#50981/, 'Err #50981 - whitespace after open delimiter with modifier');

    eval { $s->parse_string('{$foo|upper }') };
    like($@, qr/#50981/, 'Err #50981 - whitespace before close delimiter with modifier');
}

# #50981 - whitespace next to delimiter: text containing braces is exempt
{
    my $s = setup_sluz();

    my $out = $s->parse_string('function(foo) { $i = 10; }');
    is($out, 'function(foo) { $i = 10; }', 'Brace-containing text is left untouched');

    $out = $s->parse_string('foo() { bar }');
    is($out, 'foo() { bar }', 'Function-body-like text is left untouched');

    eval { $s->parse_string('{ 3 + 4 }') };
    like($@, qr/#50981/, 'Err #50981 - whitespace around expression');
}

# Ported from PHP Error #5-12, Comment #7, Basic #46-48 (runtime + unclosed)
# Note: PHP treats bareword `Scott` and `1/0` as fatal; Perl treats them
# as strings/Inf respectively, so those expectations are adapted.
{
    my $s = setup_sluz();

    eval { $s->parse_string('{undefined_func()}') };
    like($@, qr/#18933/, 'Err #18933 - call to undefined function');

    eval { $s->parse_string('{1/0}') };
    like($@, qr/#18933/, 'Err #18933 - division by zero (int)');

    eval { $s->parse_string('{if $first == Scott}YES{/if}') };
    like($@, qr/#18933/, 'Err #18933 - undefined constant in condition');

    eval { $s->parse_string('{if $bogus_var}A{elseif $first == Scott}B{/if}') };
    like($@, qr/#18933/, 'Err #18933 - undefined constant in elseif');

    eval { $s->parse_string('{if $x}foo') };
    like($@, qr/#45821/, 'Err #45821 - unclosed if');

    eval { $s->parse_string('{if $x}foo{else}bar') };
    like($@, qr/#45821/, 'Err #45821 - unclosed if with else');

    eval { $s->parse_string('{foreach $array as $item}foo') };
    like($@, qr/#45821/, 'Err #45821 - unclosed foreach');

    eval { $s->parse_string('{literal}foo') };
    like($@, qr/#45821/, 'Err #45821 - unclosed literal');
}

done_testing();
