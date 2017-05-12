package Pod::Tree::Stream;
use strict;
use warnings;

our $VERSION = '1.25';

sub new {
	my ( $package, $fh ) = @_;

	my $stream = {
		fh   => $fh,
		line => ''
	};

	bless $stream, $package;
}

sub get_paragraph {
	my $stream = shift;
	my $fh     = $stream->{fh};
	my $line   = $stream->{line};

	defined $line or return undef;    ##no critic (ProhibitExplicitReturnUndef)

	my (@lines) = ($line);
	while ( $line = $fh->getline ) {
		push @lines, $line;
		$line =~ /\S/ or last;
	}

	while ( $line = $fh->getline ) {
		$line =~ /\S/ and last;
		push @lines, $line;
	}

	$stream->{line} = $line;
	join '', @lines;
}

1;

