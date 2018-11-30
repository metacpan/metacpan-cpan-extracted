package Pod::Tree::StrStream;
use 5.006;
use strict;
use warnings;

our $VERSION = '1.27';

sub new {
	my ( $class, $ref ) = @_;

	if ($ref) {
		return bless $ref, $class;
	}
	else {
		my $st = '';
		return bless \$st, $class;
	}
}

sub print {
	my $st = shift;
	$$st .= join( '', @_ );
}

sub get {
	my $st = shift;
	my $s  = $$st;
	$$st = '';
	$s;
}

1;

