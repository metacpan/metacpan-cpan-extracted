package Protocol::SPDY::Frame::HeaderSupport;
$Protocol::SPDY::Frame::HeaderSupport::VERSION = '1.001';
use strict;
use warnings;

=head1 NAME

Protocol::SPDY::Frame::HeaderSupport - helper methods for frames which contain header data

=head1 VERSION

version 1.001

=head1 SYNOPSIS

=head1 DESCRIPTION

The SYN_STREAM, SYN_REPLY and HEADERS frame types all use the same method for specifying
HTTP-style headers. This class provides common methods for interacting with that header
data.

Mainly for internal use - see L<Protocol::SPDY> and L<Protocol::SPDY::Base>
instead.

=cut

use Protocol::SPDY::Constants ':all';

=head2 header

Returns undef if the given header is not found, otherwise returns
a scalar holding the \0-separated values found for this header.

=cut

sub header {
	my $self = shift;
	my $k = shift;
	my ($hdr) = grep $_->[0] eq $k, @{$self->{headers}};
	return undef unless $hdr;
	return join "\0", @$hdr[1..$#$hdr];
}

=head2 headers

Returns the arrayref structure of headers.

 [ [ header1 => value1, value2 ], [ header2 => value... ] ]

=cut

sub headers { shift->{headers} }

=head2 header_list

Returns the list of header names (in the order in which we received them).

=cut

sub header_list {
	my $self = shift;
	map $_->[0], @{$self->{headers}};
}

=head2 header_line

Returns a string describing the current header values, for debugging.

=cut

sub header_line {
	my $self = shift;
	join ',', map { $_->[0] . '=' . join ',', @{$_}[ 1 .. $#{$_} ] } @{$self->{headers}};
}

=head2 headers_as_hashref

Returns a hashref representation of the headers. Values
are all arrayrefs.

=cut

sub headers_as_hashref {
	my $self = shift;
	# this all seems needlessly overcomplicated
	my %h = map {
		$_->[0] => [ @{$_}[ 1 .. $#{$_} ] ]
	} @{$self->{headers}};
	\%h
}

=head2 headers_as_simple_hashref

Returns a hashref representation of the headers where values
are comma-separated strings.

=cut

sub headers_as_simple_hashref {
	my $self = shift;
	# this all seems needlessly overcomplicated
	my %h = map {
		$_->[0] => join ',', @{$_}[ 1 .. $#{$_} ]
	} @{$self->{headers}};
	\%h
}

=head2 header_hashref_to_arrayref

Converts a hashref of key=>value information into an arrayref structure.

=cut

sub header_hashref_to_arrayref {
	my $self = shift;
	my $hdr = shift;
	return [
		map {; [ $_ => split /\0/, $hdr->{$_} ] } sort keys %$hdr
	]
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
