use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use_ok('Pod::PseudoPod::DOM') or exit;

my $parser = Pod::PseudoPod::DOM->new(
    formatter_role => 'Pod::PseudoPod::DOM::Role::HTML'
);
isa_ok $parser, 'Pod::PseudoPod::DOM';

my $result = parse( <<END_POD );
=head0 Some Title

Some paragraph.

=head1 Some Title with C<Code> and I<Emphasized> and B<Bold>

Another paragraph.

Still more paragraphs.

When will the paragraphs end?

=begin sidebar

=head2 A Header I<Nested> in a Sidebar

This sidebar has a list of items:

=over 4

=item * One

=item * Deux

=item * Tres

=back

Is it not nifty?

=end sidebar

END_POD

my $link = encode_link( 'SomeTitle' );
like $result, qr!<h1 id="$link">Some Title</h1>!,
    '=head0 to <h1> title';

$link = encode_link( 'SomeTitlewithCodeandEmphasizedandBold' );
like $result,
    qr!<h2 id="$link">Some Title with <code>Code</code>!,
    'C<> tag nested in =headn';
like $result, qr!<h2 id="$link">Some Title.+?<em>Emphasized</em>!,
    'I<> tag nested in =headn';
like $result, qr!<h2 id="$link">Some Title.+?<strong>Bold</strong>!,
    'B<> tag nested in =headn';

$link = encode_link( 'AHeaderNestedinaSidebar' );
like $result,
    qr|<div class="sidebar">[^>]+<h3 id="$link">A Head|,
    '=headn nested in sidebar';

like $result, qr!<ul>[^>]+<li>One.*</div>!s,
    'list nested in sidebar';
done_testing;
