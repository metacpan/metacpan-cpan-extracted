#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Tests of the string processing mechanism

my $template = Positron::Template->new();
is($template->process("Hello, World", {}), 'Hello, World', "Non-template string works");
is($template->process('Test {$abc}', {abc => 'one'}), 'Test one', "Template string works");
is($template->process('Test {$def} {$abc}', {abc => 'one', def => 'two'}), 'Test two one', "Template string works");

# more complex expressions
is($template->process('Test {$ "direct" }', {}), 'Test direct', "Literal string in expression");
is($template->process('Test {$ loop ? loop.0 : "nothing" }', { loop => ['first']}), 'Test first', "Ternary and loop in expression");

# Quantifiers
is($template->process("The \n \t{\$-old} \n line", {old => 'new'}), "Thenewline", "Minus quantifier");
is($template->process("The \n \t{\$*old} \n line", {old => 'new'}), "The new line", "Star quantifier");
is($template->process("The \n \t{\$-old} \n line", {old => ''}), "Theline", "Minus quantifier");
is($template->process("The \n \t{\$*old} \n line", {old => ''}), "The line", "Star quantifier");

# Comments
is($template->process("Test {# of the } System", {' of the ' => ' THE ' }), "Test  System", "Comment");
is($template->process("Test \n {#} \n System", {}), "Test \n  \n System", "Empty Comment");
is($template->process("Test {#\$old} System", {old => 'new'}), "Test  System", "Comment with \$");
is($template->process("Test {#{\$old}} System", {old => 'new'}), "Test  System", "Comment around element, which gets evaluated first");
is($template->process("Test \n {#- of the } \n System", {' of the ' => ' THE ' }), "TestSystem", "Comment with -");
is($template->process("Test {#*} System", {}), "Test System", "Comment with *");
is($template->process("Test {#* of the } System", {}), "Test System", "Empty Comment with *");

# Voider
is($template->process("Test {~} System", {}), "Test  System", "Voider");
is($template->process("Test \t {~-} System", {}), "TestSystem", "Voider -");
is($template->process("Test \n \t{~*}System", {}), "Test System", "Voider *");
is($template->process("Test {~old} System", {old => 'new'}), "Test  System", "Voider ignores content (we won't complain)");
is($template->process("Test {{~}\$old} System", {old => 'new'}), "Test {\$old} System", "Voider protects strings");
is($template->process("Test {{~}# not a comment } System", {old => 'new'}), "Test {# not a comment } System", "Voider protects comments");
is($template->process("Test {{~}~} System", {old => 'new'}), "Test {~} System", "Voider protects voider");

done_testing();
