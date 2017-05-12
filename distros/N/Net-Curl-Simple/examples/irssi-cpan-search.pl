=head1 Irssi CPAN search

This example searches modules on CPAN.

=cut

use strict;
use warnings;
use Irssi;
use URI::Escape;
use Net::Curl::Simple;

my $max_pages = 5;

sub got_body
{
	my ( $window, $easy ) = @_;
	if ( my $result = $easy->code ) {
		warn "Could not download $easy->{uri}: $result\n";
		return;
	}

	my @found;
	while ( $easy->{body} =~ s#<h2 class=sr><a href="(.*?)"><b>(.*?)</b></a></h2>## ) {
		my $uri = $1;
		$_ = $2;
		s/&#(\d+);/chr $1/eg;
		chomp;
		push @found, $_;
	}
	@found = "no results" unless @found;
	my $msg = "CPAN search %9$easy->{args}%n $easy->{page}%9:%n "
		. (join "%9;%n ", @found);
	if ( $window ) {
		$window->print( $msg );
	} else {
		Irssi::print( $msg );
	}

	return if ++$easy->{page} > $max_pages;
	$easy->{body} =~ m#<a href="(.*?)">Next &gt;&gt;</a>#;
	return unless $1;
	$easy->get( $1, sub { got_body( $window, @_ ) } );
}

sub cpan_search
{
	my ( $args, $server, $window ) = @_;

	my $query = uri_escape( $args );
	my $uri = "http://search.cpan.org/search?query=${query}&mode=all&n=20";
	my $easy = Net::Curl::Simple->new();
	$easy->{args} = $args;
	$easy->{page} = 1;
	$easy->get( $uri, sub { got_body( $window, @_ ) } );
}

Irssi::command_bind( 'cpan', \&cpan_search );

# vim: ts=4:sw=4
