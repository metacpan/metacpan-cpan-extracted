#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use Pod::Abstract;

my $pod = q~
=head1 NAME

Example - Example POD document.

=head1 DESCRIPTION

This is an I<example POD document> for testing purposes. We are going
to parse and traverse it.

=head1 FUNCTIONS

=head2 example_method

 my $v = sample_call($x); # Gives a result

This would be typical for a perl module.

=over

=item *

This would be a bulleted list

=item *

Explaining what to do

=over

=item 1

This one would be a nested numbered list

=item 2

This would also

=back

=item *

Back in the bullets

=back

=cut

sub sample_call {
    # Do some code. This is a "cut" node.
}

=head2 begin/end

=begin markdown

* I wouldn't expect this to be parsed internally by Pod::Abstract.
* This would instead be a single text node - POD sequences like C<this>
  are just normal text.

=end

=begin :special

These I<should> be parsed.

It's a special trait of POD that : at the begining of a POD block is
meant to have its internals parsed as POD.

=end

=for example this would not be parsed.

=for :example but B<this> would.

=head1 SEE ALSO

L<perlfunc/wantarray> is a link to a function inside a standard document.

L<Pod::Abstract> is a link to a module.

L<Pod::Abstract/load_string> is a link to a section in a module.

L<perlsyn/"For Loops"> is a quoted section name.

L<Pod Abstract is Great|Pod::Abstract> has link text.

L<Test Hyperlink|https://metacpan.org/>

=cut

~;

my $pa = Pod::Abstract->load_string($pod);

ok($pa, "Sample POD parsed");

subtest 'Document Links' => sub {
    my @links = $pa->select('//:L');
    ok(@links == 6, "Found 5 links in the document");

    my $li = $links[0]->link_info;
    is( $li->{text}, 'perlfunc', 'Perlfunc link had expected text' );
    is( $li->{section}, 'wantarray', 'And linked to "wantarray"' );

    $li = $links[1]->link_info;
    is( $li->{text}, 'Pod::Abstract', 'Module link is Pod::Abstract' );
    is( $li->{document}, 'Pod::Abstract', 'Document is same');
    ok( !$li->{section}, 'Section is not defined');

    $li = $links[2]->link_info;
    is( $li->{text}, 'Pod::Abstract', 'Module link is Pod::Abstract' );
    is( $li->{document}, 'Pod::Abstract', 'Document is same');
    is( $li->{section}, 'load_string', 'Section is load_string');

    $li = $links[3]->link_info;
    is( $li->{text}, 'perlsyn', 'Link text is perlsyn');
    is( $li->{section}, '"For Loops"', 'Section is "For Loops"');

    $li = $links[4]->link_info;
    is( $li->{text}, "Pod Abstract is Great", 'Link text is "Pod Abstract is Great"');
    is( $li->{document}, "Pod::Abstract", 'Document is Pod::Abstract');

    $li = $links[5]->link_info;
    is( $li->{text}, 'Test Hyperlink', 'Link text is "Test Hyperlink"' );
    is( $li->{url}, 'https://metacpan.org/', 'Link to metacpan' );
};

subtest 'begin/end and custom nodes' => sub {
    # =begin/=end
    my ($hdg) =  $pa->select(q{/head1[@heading eq 'FUNCTIONS']/head2[@heading eq 'begin/end']});
    my @special = $hdg->select(qq{/begin[. eq ':special']});
    ok( @special == 1, "Found 1 ':special'");

    # : means the inner parts should be parsed - there should be 7
    # nodes in there if we flatten them out
    my @s_inner = $special[0]->select('//'); # All nodes.
    ok( @s_inner == 7, "7 inner nodes in the :special node");
    ok( (grep { $_->type eq ':I' } @s_inner), "Found the italic node");

    my @markdown = $hdg->select(qq{/begin[. eq 'markdown']});
    ok( @markdown == 1, "Found 1 'markdown'");

    # This shouldn't be parsed, it should be only one text node.
    my @m_inner = $markdown[0]->select('//');
    ok( @m_inner == 1, "Only one inner node");
    is( $m_inner[0]->type, ':text', "Inner node is a text node" );

    # =for
    my @for = $hdg->select(q{/for});
    ok( @for == 2, "Two :fors");

    my @for_ex = $hdg->select(q{/for[. eq 'example']});
    ok( @for_ex == 1, "One =for example" );

    my @fenodes = $for_ex[0]->select("//");
    ok( @fenodes == 1 && $fenodes[0]->type eq ':text', "And it's just one text node - not parsed");

    my @for_ex2 = $hdg->select(q{/for[. eq ':example']});
    ok( @for_ex2 == 1, "One =for :example" );
    
    my @fenodes2 = $for_ex2[0]->select("//");
    ok( @fenodes2 == 4, "Four nodes, looks parsed" );
    ok( (grep {$_->type eq ':B'} @fenodes2), "Found the bold text" );

};

subtest 'List Items' => sub {
    my @list_numbered = $pa->select("//head2/over//over/item");
    ok(@list_numbered == 2, "Found 2 nested list items");
};

subtest 'Round Trip' => sub {
    is($pod, $pa->pod, "Document round-trip with no changes");
};

1;