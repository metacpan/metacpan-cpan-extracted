package MySQL::Util::Lite::Column;

our $VERSION = '0.01';

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';

has name => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has key => (
	is => 'ro',
	isa => 'Str|Undef',
);

has default => (
	is => 'ro',
	isa => 'Str|Undef',
);

has type => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has is_null => (
	is => 'ro',
	isa => 'Bool',
	required => 1,
);

has is_autoinc => (
	is => 'ro',
	isa => 'Bool',
	default => 0,
);

method get_moose_type {

	my $str;
	my $type = $self->type;
	
	if ( $type =~ /varchar/i ) {
		$str = 'Str|HashRef';
	}
	elsif ( $type =~ /timestamp/i || $type =~ /datetime/i) {
		$str = 'Str|HashRef';
	}
	elsif ( $type =~ /enum/i ) {
		$str = 'Str|HashRef';
	}
	else {
		$str = 'Num|HashRef';
	}

	if ( $self->is_null ) {
		$str .= '|Undef';
	}

	return $str;
}

1;
