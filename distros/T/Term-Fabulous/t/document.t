use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use DocumentTest;
use Term::Fabulous::Document;
use Term::Fabulous::Termbox qw(TB_BOLD);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Text;

my $SAMPLE = sample_document();

subtest 'parameters' => sub {
	like dies { Term::Fabulous::Document->new( source => [] ) },         qr/source must be a string/,                                          'the source is a path';
	like dies { Term::Fabulous::Document->new( look   => 'No::Look' ) }, qr/look must be the name of a loaded Term::Fabulous::Document::Look/, 'the look is a look class';
	is( Term::Fabulous::Document->new->count,                      0,                                'a document may be empty' );
	is( Term::Fabulous::Document->new( source => 'a.md' )->source, 'a.md',                           'and remembers its source' );
	is( Term::Fabulous::Document->new->look,                       'Term::Fabulous::Document::Look', 'the base look by default' );
};

subtest 'items and their options' => sub {
	my $document = Term::Fabulous::Document->new;
	my $box      = Term::Fabulous::Widget::Box->new;
	ref_is $document->add( $box, indent => 3, quote => 1 ), $box, 'add returns the widget';
	is $document->options_of(0), { gap => 1, indent => 3, flush => 0, quote => 1, rows => undef }, 'the options, with their defaults';
	$document->options_of(0)->{gap} = 9;
	is $document->options_of(0)->{gap},                                                        1,            'as a copy';
	is [ $document->index_of($box), $document->index_of( Term::Fabulous::Widget::Box->new ) ], [ 0, undef ], 'index_of';
	like dies { $document->add($box) },                                            qr/the widget is item 0 of the document already/, 'an item is added once';
	like dies { $document->add('box') },                                           qr/add needs a widget, got 'box'/,                'an item is a widget';
	like dies { $document->add( Term::Fabulous::Widget::Box->new, colour => 1 ) }, qr/unknown option\(s\) colour/,                   'options are checked';
	like dies { $document->add( Term::Fabulous::Widget::Box->new, gap => -1 ) },   qr/gap must be a non-negative integer/,           'and their values';
	my $inner = Term::Fabulous::Widget::Text->new( text => 'x' );
	$box->add_child($inner);
	like dies { $document->add($inner) }, qr/without a parent; this one is a child of Term::Fabulous::Widget::Box/, 'a widget with a parent is refused';
	like dies { $document->item(1) },     qr/item 1 does not exist, the document has 1 items/,                      'item checks the index';
};

subtest 'factories' => sub {
	my ( $heading, $level1 ) = ( $SAMPLE->item(6), $SAMPLE->item(0) );
	is [ $heading->text, $heading->spans->[0][2]{color} ], [ 'Methods', 'text_bright' ], 'a heading is a text in the style of its level, as palette tokens';
	isa_ok $level1,                ['Term::Fabulous::Widget::Box'],     'a first-level heading is a box';
	isa_ok $level1->children->[1], ['Term::Fabulous::Widget::Divider'], 'with a rule under its text';
	is $SAMPLE->options_of(0)->{flush}, 1, 'headings are flush';

	my $marks = $SAMPLE->item(5);
	is [ map { $_->[2] } @{ $marks->links } ], [ 'Other', '/Methods' ], 'link marks become links';
	is $marks->spans->[0], [ 5, 9, { set => TB_BOLD, clear => 0, color => undef, background => undef } ], 'the other marks spans in the styles of their kinds';
	my $markup = document( [ paragraph => { markup => 'Press [bold]Enter[/] or see [link=help]help[/].' } ] )->item(0);
	is [ $markup->text, scalar @{ $markup->spans }, $markup->links->[0][2] ], [ 'Press Enter or see help.', 1, 'help' ], 'markup gives the text, spans and links';

	like dies { document( [ paragraph => marked('<shiny>x</shiny>') ] ) },    qr/unknown kind 'shiny'; the kinds are /,      'a kind the look has no style for';
	like dies { document( [ paragraph => { text => 'x', size => 1 } ] ) },    qr/a paragraph does not know size/,            'a text knows text, marks and markup';
	like dies { document( [ paragraph => [] ] ) },                            qr/a paragraph needs a string, \{ text => /,   'and is a string or a hash';
	like dies { document( [ list_item => '10.', 'x', marker_width => 3 ] ) }, qr/leaves no space after the marker/,          'the marker leaves a space';
	like dies { document( [ heading => 7, 'X' ] ) },                          qr/a heading level is an integer from 1 to 6/, 'heading levels are 1 to 6';

	my $item = $SAMPLE->item(12);
	is [ map { $_->text } $SAMPLE->texts(12) ],                              [ "\x{2022}", 'First point.' ], 'a list item is a marker and a text';
	is [ $item->children->[1]->search_texts ],                               [ [ undef, 'First point.' ] ],  'the text is searched';
	is [ map { scalar( () = $_->search_texts ) } $SAMPLE->searchables(12) ], [ 0, 1 ],                       'the marker has nothing to search';

	my @code = $SAMPLE->code_blocks;
	is [ scalar @code, $code[0]->language, $code[0]->look_class ], [ 1, 'perl', 'Term::Fabulous::Document::Look' ], 'code is a code block with the language and the look';
	isa_ok document( [ rule => () ] )->item(0), ['Term::Fabulous::Widget::Divider'], 'a rule is a divider';
};

subtest 'the factories space the items' => sub {
	is [ map { $SAMPLE->kind_of($_) } 0, 1, 3, 7, 12 ],        [qw(heading paragraph code term item)], 'kind_of names the factory';
	is document( [ rule => () ] )->kind_of(0),                 'rule',                                 'a rule too';
	is [ map { $SAMPLE->options_of($_)->{gap} } 7, 8, 9, 10 ], [ 1, 0, 1, 0 ],                         'a definition follows its term';
	is [ map { $SAMPLE->options_of($_)->{gap} } 12 .. 15 ],    [ 1, 0, 1, 0 ],                         'the items of a list follow each other, a new list is apart';
	my $nested = document( [ list_item => '-', 'outer' ], [ list_item => '-', 'inner', indent => 2 ], [ list_item => '-', 'outer again', position => 2 ] );
	is [ map { $nested->options_of($_)->{gap} } 0 .. 2 ],                                      [ 1, 0, 0 ], 'a nested list starts right under its parent';
	is document( [ paragraph => 'a' ], [ paragraph => 'b', gap => 3 ] )->options_of(1)->{gap}, 3,           'a gap given wins';
};

subtest 'sections' => sub {
	is [ map { $_->{title} } $SAMPLE->sections ], [ 'NAME', 'SYNOPSIS', 'DESCRIPTION', 'Methods', 'Lists', 'SEE ALSO' ], 'the headings start the sections';
	is( ( $SAMPLE->sections )[3], { item => 6, level => 2, title => 'Methods' }, 'with their item, level and title' );
	is [ $SAMPLE->section_count, $SAMPLE->item_of_section(3), $SAMPLE->level_of_section(3), $SAMPLE->title_of_section(3) ], [ 6, 6, 2, 'Methods' ], 'by number';
	is [ $SAMPLE->section_at(6), $SAMPLE->section_at(7) ],                                                                  [ 3, 3 ], 'a section holds its heading and the items after it';
	is document( [ paragraph => 'Before.' ], [ heading => 1, 'A' ] )->section_at(0),                                        undef,    'an item before the first section is in none';
	my $widget = Term::Fabulous::Document->new;
	$widget->add( Term::Fabulous::Widget::Box->new, section => [ 2, 'A table' ] );
	is [ $widget->title_of_section(0), $widget->level_of_section(0) ], [ 'A table', 2 ], 'any item can start a section';
	like dies { $SAMPLE->title_of_section(6) },                                            qr/section 6 does not exist, the document has 6 sections/, 'a section number beyond the last dies';
	like dies { $SAMPLE->item_of_section('Lists') },                                       qr/item_of_section needs a section number, got 'Lists'/,   'and so does a number that is none';
	like dies { $widget->add( Term::Fabulous::Widget::Box->new, section => [ 7, 'x' ] ) }, qr/a section level is an integer from 1 to 6/,             'levels are 1 to 6';
};

subtest 'find_section' => sub {
	my $text_at = sub ($name) { my $index = $SAMPLE->find_section($name); defined $index ? ( $SAMPLE->texts($index) )[0]->text : undef };
	is $text_at->('Methods'),    'Methods',          'a section by its title';
	is $text_at->('methods'),    'Methods',          'ignoring case when nothing matches exactly';
	is $text_at->('new'),        'new',              'a term by its anchor';
	is $text_at->('frobnicate'), 'frobnicate VALUE', 'an anchor that starts with the name as a word';
	is $text_at->('frob'),       undef,              'but not with part of a word';
	is $text_at->("SEE\n ALSO"), 'SEE ALSO',         'whitespace is squeezed';
	is $text_at->(''),           undef,              'an empty name finds nothing';
	like dies { $SAMPLE->find_section(undef) }, qr/find_section needs a section name/, 'a name is needed';
};

subtest 'find_text' => sub {
	my $long = long_document();
	is scalar( my @all = $long->find_text('needle') ), 120, 'one match per paragraph';
	is [ ( $long->find_text('Needle') )[0] ],          [],  'a capital letter matches case';
	my ($bold) = $SAMPLE->find_text('bold');
	is [ $bold->[0], $bold->[2], $bold->[3], $bold->[4] ], [ 5, undef, 5, 9 ], 'a match names the item, the key and the offsets';
	ref_is $bold->[1], $SAMPLE->item(5), 'and the widget that shows the text';
	is [ $SAMPLE->find_text('') ],                                                           [],                     'an empty query finds nothing';
	is [ map { [ @$_[ 3, 4 ] ] } document( [ paragraph => 'aaaa' ] )->find_text('aa') ],     [ [ 0, 2 ], [ 2, 4 ] ], 'matches do not overlap';
	is [ map { [ @$_[ 3, 4 ] ] } document( [ paragraph => 'a.b axb' ] )->find_text('a.b') ], [ [ 0, 3 ] ],           'the query is text, not a pattern';
	is [ map { $_->[0] } $SAMPLE->find_text('Sample') ],                                     [ 1, 3, 3 ],            'code is searched too';

	my $with_table = document( [ paragraph => 'Above.' ] );
	$with_table->add( Term::Fabulous::Widget::Table->new( id => 't', columns => [ { key => 'name' } ], rows => [ map { { id => $_, name => "row $_" } } 1 .. 9 ], page_size => 2 ) );
	my ($row) = $with_table->find_text('row 9');
	is [ $row->[0], $row->[2] ], [ 1, [ 9, 'name' ] ], 'a table answers for its rows on every page';
	like dies { $SAMPLE->find_text( [] ) }, qr/find_text needs a string/, 'a query is a string';
};

done_testing;
