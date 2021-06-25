#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Pod::PseudoPod::DOM;
use MIME::Base64 'encode_base64url';

exit main( @ARGV );

sub main
{
    use_ok( 'Pod::PseudoPod::DOM::Index' );

    test_simple_index();
    test_multiple_index();
    test_multiple_entries_in_one_index();
    test_subentries();
    test_subsubentries();
    test_subentry_with_entry();

    done_testing();
    return 0;
}

sub make_index_nodes
{
    my $doc   = qq|=head0 My Document\n\n|;
    my $count = 0;

    for my $tag (@_)
    {
        $doc .= qq|=head1 Index Element $count\n\n$tag\n\n|;
        $count++;
    }

    my $parser = Pod::PseudoPod::DOM->new(
        formatter_role => 'Pod::PseudoPod::DOM::Role::HTML',
        filename       => 'dummy_file.html',
    );
    my $dom   = $parser->parse_string_document( $doc )->get_document;
    my $index = Pod::PseudoPod::DOM::Index->new;
    $index->add_entry( $_ ) for $dom->get_index_entries;

    return $index;
}

sub test_simple_index
{
    my $index = make_index_nodes( 'X<some entry>' );
    like $index->emit_index, qr!<h2>S</h2>!,
        'index should contain top-level key for all entries';
}

sub test_multiple_index
{
    my $index = make_index_nodes(
        'X<some entry>', 'X<some other entry', 'X<yet more entries>'
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>S</h2>!,
        'index should contain top-level key for all entries';

    like $output, qr!<h2>Y</h2>!,
        '... always capitalized';

    like $output, qr!some entry!,       '... with text of entry';
    like $output, qr!some other entry!, '... for each entry';
    like $output, qr!yet more entries!, '... added to index';
}

sub test_multiple_entries_in_one_index
{
    my $index = make_index_nodes(
        'X<aardvark>', 'X<Balloonkeeper>', 'X<aardvark>'
    );

    my $output = $index->emit_index;
    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<h2>B</h2>!, '... with proper capitalization';

    my $key = encode_base64url( 'aardvark' );

    like $output,
        qr!aardvark \[<a href=".+?#${key}1">1</a>\] \[.+?${key}2">2</a>\]!,
        '... with multiple entries merged';
}

sub test_subentries
{
    my $index = make_index_nodes(
        'X<animals; aardvark>', 'X<animals; blue-footed boobie>',
        'X<animals; cardinal>'
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<li>animals\n<ul>!,
        '... with top levels of nested index entries creating lists';
    like $output, qr!<li>aardvark \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>blue-footed boobie \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>cardinal \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>aardvark.+<li>blue-footed boobie.+<li>cardinal!s,
        '... in alphabetical order';
    unlike $output, qr!<li>aardvark.+?</li>.+aardvark!s,
        '... but no duplicate entries unless necessary';
}

sub test_subsubentries
{
    my $index = make_index_nodes(
        'X<animals; a-letter; aardvark>',
        'X<animals; c-letter; cardinal>',
        'X<animals; b-letter; blue-footed boobie>',
        'X<animals; a-letter; anteater>',
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<li>animals\n<ul>!,
        '... with top levels of nested index entries creating lists';
    like $output, qr!<li>aardvark \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>blue-footed boobie \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>cardinal \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>aardvark.+<li>blue-footed boobie.+<li>cardinal!s,
        '... in alphabetical order';
    unlike $output, qr!<li>aardvark.+?</li>.+aardvark!s,
        '... but no duplicate entries unless necessary';

    like $output, qr!<li>animals\n<ul>\n<li>a-letter\n!,
        '... nesting sub-entries appropriately';
    like $output, qr!<li>a-letter.+<li>b-letter.+<li>c-letter!s,
        '... in alphabetical order';
    like $output, qr!<li>aardvark.+?<li>anteater!s,
        '... with entries in alphabetical order too';

    my $key = encode_base64url( 'animals;a-letter;aardvark' );
    like $output, qr!#${key}1!, '... and full anchors';
}

sub test_subentry_with_entry
{
    my $index = make_index_nodes(
        'X<animals; aardvark>',
        'X<animals>',
        'X<animals; aardvark; Cerebus>',
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<li>animals \[!,  '... and top-level entries';
    like $output, qr!<li>aardvark \[!, '... and top-level sub-entries';
    like $output, qr!<li>Cerebus \[!,  '... and top-level sub-sub-entries';

    like $output, qr!<li>animals.+<li>animals\n!s,
        '... entries should come before subentries with the same key';
}
