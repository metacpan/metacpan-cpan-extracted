package Parse::M3U::Extended;
use warnings;
use strict;

our $VERSION = 0.3;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT_OK = qw(m3u_parser $m3u_parser);

=head1 NAME

Parse::M3U::Extended - Extended M3U playlist parser

=head1 SYNOPSIS

 use LWP::Simple;
 use Parse::M3U::Extended qw(m3u_parser);

 my $m3u = get("http://example.com/foo.m3u");
 my @items = m3u_parser($m3u);

=head1 DESCRIPTION

This module contains a simple parser for the Extended M3U
playlist format as used in e.g. HTTP Live Streaming. It also
supports the regular M3U format, usually found with digital
copies of music albums etc.

=cut

=head1 SUBROUTINES

=head2 m3u_parser

Takes a m3u playlist as a string and returns a list, with each
element is a hashref with the keys type and value. If the
playlist's first line is "#EXTM3U\n", then the elements in the
returned list can have type "directive", which has a "tag" key
and the value key is optional.

 {
   type => 'comment',
   value => 'a comment',
 }

 {
   type => 'item',
   value => 'http://example.com/foo.mp3',
 }

 {
   type => 'directive',
   tag => 'EXTM3U',
 }

 {
   type => 'directive',
   tag => 'EXT-X-ALLOW-CACHE',
   value => 'YES',
 }

=cut

sub _simple {
	my $type = shift;
	my $key = shift // 'value';
	return sub {{
		type => $type,
		$key => pop,
	}};
}

my @_tests = (
	['marker', qr/^#\s*(EXTM3U)\s*$/, _simple('directive', 'tag')],
	['directive', qr/^#\s*(EXT[^:]+)(?::(.+))?\s*/, sub {
	shift() ? {
			type => 'directive',
			tag => $_[0],
			(defined $_[1] ? (value => $_[1]) : ())
		} : _simple('comment')->($_[0] . (defined $_[1] && ":$_[1]"))
	}],
	['comment', qr/^#(.*)/, _simple('comment')],
	['item', qr/(.+)/x, _simple('item')],
);


sub m3u_parser {
	my @lines = split /\r?\n/, shift;
	my @playlist;
	my $m3ue = $lines[0] =~ /^#EXTM3U/;
	for my $l (@lines) {
		my @match = grep { defined $_->[2] }
		            map { [$_->[0], $_->[2], $l =~ /$_->[1]/] }
			    @_tests;
		my ($type, $func, @vals) = @{shift @match};
		push @playlist, $func->($m3ue, @vals);
	}

	return @playlist;
}

=head1 SEE ALSO

=over

=item * IETF Internet Draft: draft-pantos-http-live-streaming-08

=back

=head1 COPYRIGHT

Copyright (c) 2012, 2016 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
