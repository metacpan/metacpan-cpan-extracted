use strict;
use warnings;

use Test::More;
use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use_ok('Pod::PseudoPod::DOM') or exit;

my $parser = Pod::PseudoPod::DOM->new(
    formatter_role => 'Pod::PseudoPod::DOM::Role::HTML'
);
isa_ok $parser, 'Pod::PseudoPod::DOM';

my $result = parse( <<END_POD );
=begin epigraph

A witty saying proves nothing.

-- someone sensible, probably Voltaire

=end epigraph
END_POD

like $result, qr!<div class="epigraph">.*A witty.*&mdash;someone.*</div>!s,
    'epigraph handled correctly';

$result = parse( <<END_POD );
=begin blockquote

Sure, why not indent this a little bit?

=end blockquote
END_POD

like $result, qr!<div class="blockquote">\n\n<p>Sure, why not!,
    'blockquote handled correctly';


done_testing;
