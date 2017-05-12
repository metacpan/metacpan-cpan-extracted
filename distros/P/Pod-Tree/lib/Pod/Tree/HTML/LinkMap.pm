package Pod::Tree::HTML::LinkMap;
use strict;
use warnings;

our $VERSION = '1.25';

sub new {
	my $class = shift;
	bless {}, $class;
}

sub url {
	my ( $link_map, $html, $target ) = @_;

	my $depth = $html->{options}{depth};
	my $base = join '/', ('..') x $depth;

	my $page = $target->get_page;
	$page =~ s(::)(/)g;
	$page .= '.html' if $page;

	my $section  = $target->get_section;
	my $fragment = $html->escape_2396($section);

	my $url = $html->assemble_url( $base, $page, $fragment );
	$url;
}

1;
