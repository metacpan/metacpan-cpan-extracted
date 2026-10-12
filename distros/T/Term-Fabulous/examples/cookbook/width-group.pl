#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );

foreach my $pair ( [ 'Name', 'Ada Lovelace' ], [ 'Occupation', 'Mathematician' ], [ 'Born', '1815' ] ) {
	my ( $name, $value ) = @$pair;
	my $row   = Term::Fabulous::Widget::Box->new( layout      => { child_gap => 2 } );
	my $label = Term::Fabulous::Widget::Box->new( width_group => 1 );    # all labels: one group
	$label->add_child( Term::Fabulous::Widget::Text->new( text => "$name:", text_color => [ 150, 160, 180, 255 ] ) );
	$row->add_child( $label, Term::Fabulous::Widget::Text->new( text => $value, text_color => [ 255, 255, 255, 255 ] ) );
	$root->add_child($row);
}

# Colors only when STDOUT is a terminal.
Term::Fabulous::Static->new( root => $root, width => 40 )->print;
