#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('Positron::Template');
}

# Testing _make_finder despite the fact that it's "internal".
# We need to make sure it works.

my ($template, $finder);

$template = Positron::Template->new();
dies_ok { $finder = $template->_make_finder(); } "Can't make a finder for nothing";

# One for all sigils!
$finder = $template->_make_finder('!?@$%.:,;=#^~/|');
is_deeply(['' =~ m{$finder}], [], "Empty string does not match");
is_deeply(['abc' =~ m{$finder}], [], "Non-construct string does not match");
is_deeply(['$abc' =~ m{$finder}], [], "Non-construct string (no delimiters) does not match");
is_deeply(['{abc}' =~ m{$finder}], [], "Non-construct string (no sigil) does not match");
is_deeply(['{-$abc}' =~ m{$finder}], [], "Non-construct string (switched with sigil) does not match");
is_deeply(['{$abc}' =~ m{$finder}], ['$', '', 'abc'], 'Matches a $ sigil');
is_deeply(['{$ abc }' =~ m{$finder}], ['$', '', ' abc '], 'Matches a $ sigil (with whitespace)');
is_deeply(['text {$abc} matches' =~ m{$finder}], ['$', '', 'abc'], 'Matches a $ sigil inside');
is_deeply(['{~}' =~ m{$finder}], ['~', '', ''], 'Matches a naked sigil');
is_deeply(['{~+}' =~ m{$finder}], ['~', '+', ''], 'Matches a naked sigil plus quantifier');

# Quantifiers
is_deeply(['{-abc}' =~ m{$finder}], [], "Just Quantifiers does not match");
is_deeply(['{@-abc}' =~ m{$finder}], ['@', '-', 'abc'], "- Quantifier");
is_deeply(['{?+abc}' =~ m{$finder}], ['?', '+', 'abc'], "+ Quantifier");
is_deeply(['{.*abc}' =~ m{$finder}], ['.', '*', 'abc'], "* Quantifier");
is_deeply(['{@- abc }' =~ m{$finder}], ['@', '-', ' abc '], "- Quantifier (with whitespace)");

# Try them all
foreach my $sigil (split(//, '!?@$%.:,;=#^~/|')) {
    foreach my $quant ('', '+', '-', '*') {
        is_deeply(["{${sigil}${quant}abc}" =~ m{$finder}], [$sigil, $quant, 'abc'], "Matched ${sigil}${quant} sigil + quantifier");
    }
}

# Nested and multiple
is_deeply(['{{~}$abc}' =~ m{$finder}], ['~', '', ''], "Escaped via nesting");
is_deeply(['{@abc} and {~-} such' =~ m{$finder}g], ['@', '', 'abc', '~', '-', ''], "Found both occurrences");

# Change ends
$template->{'opener'} = '[';
$template->{'closer'} = ']';
$finder = $template->_make_finder('$#~');
is_deeply(['[$abc]' =~ m{$finder}], ['$', '', 'abc'], "Alternate endings");
is_deeply(['[$*ab{}c]' =~ m{$finder}], ['$', '*', 'ab{}c'], "Alternate endings with embedded originals");
is_deeply(['{$*abc}' =~ m{$finder}], [], "Original endings no longer match");

done_testing();
