use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Object::Pad 0.825;
use Term::Fabulous::Role::SearchContainer;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

# A container whose parts are a list it keeps, in the tree or not, and
# that records which part it was asked to show.
class Test::Shelf :isa(Term::Fabulous::Widget::Box) :does(Term::Fabulous::Role::SearchContainer) {
	field @parts;
	field @shown :reader;

	method set_parts (@new)    { @parts = @new; return $self }
	method searchable_parts () { return @parts }

	method reveal_part ($part) {
		push @shown, $part;
		return;
	}
}

# One without reveal_part: its parts are always shown.
class Test::Wall :isa(Term::Fabulous::Widget::Box) :does(Term::Fabulous::Role::SearchContainer) {
	field @parts;

	method set_parts (@new)    { @parts = @new; return $self }
	method searchable_parts () { return @parts }
}

sub text ($string) { return Term::Fabulous::Widget::Text->new( text => $string ) }

subtest 'the parts are searched with nested keys' => sub {
	my ( $first, $second ) = ( text('alpha beta gamma'), text('beta') );
	my $shelf = Test::Shelf->new->set_parts( $first, $second );
	ok $shelf->DOES('Term::Fabulous::Role::Searchable'), 'a container is searchable';
	is [ $shelf->search_texts ], [ [ [ 0, undef ], 'alpha beta gamma' ], [ [ 1, undef ], 'beta' ] ], 'every part, in order, keyed by its index and its own key';
	$shelf->highlight_text( [ 1, undef ], [ [ 0, 4, 'on accent' ] ] );
	is $second->highlights->[0][1], 4, 'highlight_text reaches the part';
	$shelf->clear_text_highlights;
	is $second->highlights, [], 'clear_text_highlights clears every part';
	like dies { $shelf->search_revision('first') }, qr/search_revision needs a key of \[ index, key \], got 'first'/, 'a key is [ index, key ]';
};

subtest 'the revision names the part at the index' => sub {
	my ( $first, $second ) = ( text('alpha beta gamma'), text('beta') );
	my $shelf    = Test::Shelf->new->set_parts( $first, $second );
	my $revision = $shelf->search_revision( [ 0, undef ] );
	is $revision, $first->search_serial . ':' . $first->content_revision, 'the serial of the part and its own revision';
	$first->text('alpha');
	isnt $shelf->search_revision( [ 0, undef ] ), $revision, 'it changes with the text';
	$revision = $shelf->search_revision( [ 0, undef ] );
	$shelf->set_parts($second);
	isnt $shelf->search_revision( [ 0, undef ] ), $revision, 'and when another part comes to the index, though its own revision may be the same';
	is $shelf->search_revision( [ 1, undef ] ),   'gone',    'a key past the parts is gone';
	ok $second->search_serial > $first->search_serial, 'serials are given in the order the widgets are made';
};

subtest 'revealing shows the part first' => sub {
	my ( $first, $second ) = ( text('one'), text('two') );
	my $shelf = Test::Shelf->new->set_parts( $first, $second );
	my ($shown) = @{ $shelf->reveal_text( [ 1, undef ], 0 ) };
	ref_is $shown, $second, 'the part reveals its text';
	ref_is( ( $shelf->shown )[0], $second, 'after reveal_part was asked to show it' );
	is $shelf->reveal_text( [ 5, undef ], 0 ), [ undef, undef ], 'a key past the parts reveals nothing';
	my @asked = $shelf->shown;
	is scalar @asked, 1, 'and asks to show nothing';
	ref_is( Test::Wall->new->set_parts($first)->reveal_text( [ 0, undef ], 0 )->[0], $first, 'reveal_part is optional' );
};

done_testing;
