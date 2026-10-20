use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Termbox qw(TB_BOLD TB_ITALIC TB_UNDERLINE);
use Term::Fabulous::Text::Marks;
use Term::Fabulous::Theme;

my $theme = Term::Fabulous::Theme->builtin('dark');

sub marks (%parameters) {
	return Term::Fabulous::Text::Marks->new( owner => 'My::Widget', %parameters );
}

# The runs as [ from, to, set bits, color ] for short assertions.
sub cut ( $marks, %options ) {
	return [ map { [ $_->[0], $_->[1], $_->[2]{set}, $_->[2]{color} ] } @{ $marks->runs( theme => $theme, %options ) } ];
}

subtest 'runs cut the text at every boundary and stack the styles in order' => sub {
	my $marks = marks( text => 'abcdefgh', spans => [ [ 0, 6, 'bold red' ], [ 2, 4, 'italic blue' ] ] );
	is cut($marks), [ [ 0, 2, TB_BOLD, [ 255, 0, 0, 255 ] ], [ 2, 4, TB_BOLD | TB_ITALIC, [ 0, 0, 255, 255 ] ], [ 4, 6, TB_BOLD, [ 255, 0, 0, 255 ] ], [ 6, 8, 0, undef ] ],
		'overlaps and nesting: a later span wins where it covers an earlier one, uncovered text is neutral';
	$marks->set_spans( [ [ 2, 4, 'italic blue' ], [ 0, 6, 'bold red' ] ] );
	is cut($marks)->[1], [ 2, 4, TB_BOLD | TB_ITALIC, [ 255, 0, 0, 255 ] ], 'the order given decides, not where a span starts';
	$marks->set_highlights( [ [ 3, 5, 'green' ] ] );
	is cut($marks)->[2], [ 3, 4, TB_BOLD | TB_ITALIC, [ 0, 128, 0, 255 ] ], 'highlights stack over the spans';
	is cut(
		$marks, under => [ marks( text => 'abcdefgh' )->check_spans( span => [ [ 6, 8, 'underline' ] ] ) ],
		over => [ [ 0, 1, { set => 0, clear => TB_BOLD, color => undef, background => undef } ] ]
		)->[0], [ 0, 1, 0, [ 255, 0, 0, 255 ] ],
		'over ranges stack last';
	is cut( $marks, under => [ $marks->check_spans( span => [ [ 0, 8, 'yellow' ] ] ) ] )->[-1],        [ 6, 8, 0, [ 255, 255, 0, 255 ] ], 'under ranges stack first';
	is cut( marks( text => 'ab', spans => [ [ 1, 1, 'bold' ] ] ) ),                                    [ [ 0, 2, 0, undef ] ],            'an empty range covers nothing';
	is marks( text => '' )->runs( theme => $theme ),                                                   [],                                'an empty text has no runs';
	is marks( text => 'ab', spans => [ [ 0, 2, 'accent' ] ] )->runs( theme => $theme )->[0][2]{color}, $theme->token('accent'),           'palette tokens are resolved against the theme';
	like dies { $marks->runs },                               qr/runs needs a theme/,                                  'a theme is needed';
	like dies { $marks->runs( theme => $theme, base => 1 ) }, qr/runs does not take base \(known: theme under over\)/, 'and other options die';
};

subtest 'ranges are checked against the text, in one wording' => sub {
	my $marks = marks( text => 'ab' );
	like dies { $marks->set_spans('bold') },                      qr/\AMy::Widget: spans must be an array reference of \[start, end, style\], got 'bold'/, 'the owner names the widget';
	like dies { $marks->set_spans( [ [ 0, 1 ] ] ) },              qr/a span is \[start, end, style\]/,                                                     'three parts';
	like dies { $marks->set_spans( [ [ 1, 0, 'bold' ] ] ) },      qr/span end 0 lies before its start 1/,                                                  'end before start';
	like dies { $marks->set_highlights( [ [ 0, 3, 'bold' ] ] ) }, qr/highlight end 3 lies past the text \(2 characters\)/,                                 'past the end';
	like dies { $marks->add_span( 'bold', -1, 1 ) },              qr/span start must be a non-negative integer, got '-1'/,                                 'negative start';
	like dies { $marks->add_span( 'shiny', 0, 1 ) },              qr/unknown style word 'shiny'/,                                                          'styles are checked';
	like dies { $marks->check_spans( 'highlighter span' => [ [ 0, 9, 'bold' ] ] ) }, qr/highlighter span end 9 lies past the text/,                        'check_spans names what it checks';
	like dies { marks( text => [] ) },                                               qr/My::Widget: text must be a string/,                                'the text is a string';
};

subtest 'links' => sub {
	my $marks = marks( text => 'one two three', links => [ [ 8, 13, 'c' ], [ 0, 3, 'a' ] ] );
	is $marks->links,                                                  [ [ 0, 3, 'a' ], [ 8, 13, 'c' ] ], 'ordered by their start';
	is $marks->add_link( 'b', 4, 7 ),                                  1,                                 'add_link returns the index it took';
	is [ $marks->link_count, $marks->link_at(5), $marks->link_at(3) ], [ 3, 1, undef ],                   'link_count and link_at';
	like dies { $marks->add_link( 'x', 2, 5 ) },                     qr/the link 2 to 5 overlaps the link 0 to 3/, 'links do not overlap';
	like dies { $marks->add_link( 'x', 3, 3 ) },                     qr/a link must not be empty, got 3 to 3/,     'nor are they empty';
	like dies { $marks->add_link( undef, 3, 4 ) },                   qr/a link needs a target/,                    'a target is needed';
	like dies { marks( text => 'ab', links => [ [ 0, 3, 'x' ] ] ) }, qr/link end 3 lies past the text/,            'offsets are checked';
	like dies { marks( text => 'ab', links => [ [ 0, 1 ] ] ) },      qr/a link is \[start, end, target\]/,         'a link has three parts';
	$marks->clear_links;
	is $marks->links, [], 'clear_links';
};

subtest 'readers return copies' => sub {
	my $marks = marks( text => 'ab', spans => [ [ 0, 1, 'bold' ] ], links => [ [ 0, 2, 'x' ] ] );
	$marks->set_highlights( [ [ 1, 2, 'red' ] ] );
	$_->[2]{set}          = 0 foreach @{ $marks->spans }, @{ $marks->highlights };
	$marks->links->[0][2] = 'y';
	is [ $marks->spans->[0][2]{set}, $marks->highlights->[0][2]{color}, $marks->links->[0][2] ], [ TB_BOLD, [ 255, 0, 0, 255 ], 'x' ], 'changing a copy changes nothing';
};

subtest 'the content revision' => sub {
	my $marks = marks( text => 'abc', spans => [ [ 0, 1, 'bold' ] ], links => [ [ 1, 2, 'x' ] ] );
	is $marks->content_revision, 0, 'starts at 0';
	my @after = map { $_->(); $marks->content_revision } sub { $marks->set_highlights( [ [ 0, 1, 'red' ] ] ) }, sub { $marks->add_span('italic') }, sub { $marks->set_spans( [] ) },
		sub { $marks->add_link( 'y', 2, 3 ) }, sub { $marks->clear_links }, sub { $marks->set_highlights( [] ) }, sub { $marks->set_text('new') };
	is \@after, [ 0, 1, 2, 3, 4, 4, 5 ], 'spans, links and the text count; highlights never do';
	is [ $marks->text, $marks->spans, $marks->highlights, $marks->links, $marks->has_marks ], [ 'new', [], [], [], 0 ], 'a new text drops every mark';
};

done_testing;
