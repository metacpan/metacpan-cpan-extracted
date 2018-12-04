package Pod::Tree::HTML::PerlTop;
use 5.006;
use strict;
use warnings;

use base qw(Pod::Tree::HTML);

our $VERSION = '1.29';

sub set_links {
	my ( $html, $links ) = @_;
	$html->{links} = $links;
}

sub _emit_verbatim {
	my ( $html, $node ) = @_;
	my $stream = $html->{stream};
	my $links  = $html->{links};
	my $text   = $node->get_text;

	$text =~ s( \n\n$ )()x;
	my @words = split m/(\s+)/, $text;

	$stream->PRE;

	for my $word (@words) {
		if ( $links->{$word} ) {
			my $link = $links->{$word};
			$stream->A( HREF => "$link.html" )->text($word)->_A;
		}
		else {
			$stream->text($word);
		}
	}

	$stream->_PRE;
}

1;
