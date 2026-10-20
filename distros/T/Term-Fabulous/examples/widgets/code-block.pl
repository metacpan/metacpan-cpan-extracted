#!/usr/bin/env perl

# Term::Fabulous::Widget::CodeBlock: code on its own background, with
# a highlighter that colors a few Perl keywords and variables, a block
# whose long lines are cut at the right edge, and the same block
# scrolled sideways. Left and Right scroll the two lower blocks
# together. Ctrl+C quits.
#
#     perl examples/widgets/code-block.pl

use v5.32;
use warnings;
use strict;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::CodeBlock;
use Term::Fabulous::Widget::Text;

# A highlighter is a function from the code and its language to spans:
# here, keywords in purple and variables in red, for Perl only.
sub highlight ( $code, $language ) {
	return [] unless ( $language // '' ) eq 'perl';
	my @spans;
	push @spans, [ $-[0], $+[0], 'bold #c678dd' ] while $code =~ /\b(?:my|sub|return|use|foreach|if|unless)\b/g;
	push @spans, [ $-[0], $+[0], '#e06c75' ]      while $code =~ /[\$\@%]\w+/g;
	return \@spans;
}

my $short = Term::Fabulous::Widget::CodeBlock->new(
	code        => join( "\n", 'sub greet ($name) {', '    my $line = "Hello, $name!";', '    return $line;', '}' ),
	language    => 'perl',
	highlighter => \&highlight,
);

my $wide = join "\n",
	'my %options = ( verbose => 1, output => "report.txt", columns => [ qw(name team started salary) ], format => "%-20s %-10s %12s %10.2f" );',
	'foreach my $row ( sort { $a->{started} cmp $b->{started} } @rows ) { printf $options{format}, @{$row}{ @{ $options{columns} } }; print "\n" }',
	'say "done";';
my $cut      = Term::Fabulous::Widget::CodeBlock->new( code => $wide, language => 'perl', highlighter => \&highlight );
my $scrolled = Term::Fabulous::Widget::CodeBlock->new( code => $wide, language => 'perl', highlighter => \&highlight, offset => 24 );

sub label ($text) {
	return Term::Fabulous::Widget::Text->new( text => $text, text_color => [ 150, 160, 180, 255 ] );
}

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2, right => 2, top => 1 },
		child_gap        => 1,
	},
);
$root->add_child(
	label('A highlighted Perl snippet:'),                                                $short,
	label('Long lines are cut at the edge and marked:'),                                 $cut,
	label('The same block, scrolled 24 columns sideways (Left and Right scroll both):'), $scrolled,
	label('Ctrl+C quits.'),
);

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$root->on(
	KeyPress => sub ($event) {
		my $name = $event->main_key_name // return;
		my $step = $name eq 'Right' ? 8 : $name eq 'Left' ? -8 : return;
		foreach my $block ( $cut, $scrolled ) {
			my $offset = $block->shown_offset + $step;    # from where the block is, not past its longest line
			$block->offset( $offset < 0 ? 0 : $offset );
		}
		return;
	}
);
$ui->run;
