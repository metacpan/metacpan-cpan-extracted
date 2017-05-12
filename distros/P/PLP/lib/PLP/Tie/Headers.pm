package PLP::Tie::Headers;

use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

=head1 PLP::Tie::Headers

Makes a hash case insensitive, and sets some headers. <_> equals <->, so C<$foo{CONTENT_TYPE}> is
the same as C<$foo{'Content-Type'}>.

	tie %somehash, 'PLP::Tie::Headers';

This module is part of the PLP internals and probably not of much use to others.

=cut

sub TIEHASH {
	return bless [ # Defaults
		{
			'Content-Type'  => 'text/html',
			'X-PLP-Version' => $PLP::VERSION,
		},
		{
			'content-type'  => 'Content-Type',
			'x-plp-version' => 'X-PLP-Version',
		},
		1  # = content-type untouched
	], $_[0];
}

sub FETCH {
	my ($self, $key) = @_;
	if ($self->[2] and defined $self->[0]->{'Content-Type'}) {
		my $utf8 = eval { grep {$_ eq "utf8"}  PerlIO::get_layers(*STDOUT) };
		$self->[0]->{'Content-Type'} .= '; charset=utf-8' if $utf8;
		$self->[2] = 0;
	}
	$key =~ tr/_/-/;
	defined ($key = $self->[1]->{lc $key}) or return;
	return $self->[0]->{$key};
}

sub STORE {
	my ($self, $key, $value) = @_;
	$key =~ tr/_/-/;
	if ($PLP::sentheaders) {
		my @caller = caller;
		die "Can't set headers after sending them at " .
		    "$caller[1] line $caller[2].\n(Output started at " .
		    "$PLP::sentheaders->[0] line $PLP::sentheaders->[1].)\n"
	}
	if (defined $self->[1]->{lc $key}){
		$key = $self->[1]->{lc $key};
	} else {
		$self->[1]->{lc $key} = $key;
	}
	$self->[2] = 0 if $key eq 'Content-Type';
	return ($self->[0]->{$key} = $value);
}

sub DELETE {
	my ($self, $key) = @_;
	$key =~ tr/_/-/;
	defined ($key = delete $self->[1]->{lc $key}) or return;
	return delete $self->[0]->{$key};
}

sub CLEAR {
	my $self = $_[0];
	return (@$self = ());
}

sub EXISTS {
	my ($self, $key) = @_;
	$key =~ tr/_/-/;
	return exists $self->[1]->{lc $key};
}

sub FIRSTKEY {
	my $self = $_[0];
	keys %{$self->[0]};
	return each %{ $self->[0] }; # Key only, Tie::Hash doc is wrong.
}

sub NEXTKEY {
	return each %{ $_[0]->[0] };
}

1;

