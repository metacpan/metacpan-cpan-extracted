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
	is => 'rw',
	isa => 'Bool',
	required => 1,
);

has is_autoinc => (
	is => 'rw',
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

method get_ddl {
    my $sql = "`" . $self->name . "` " . $self->type . ' ';
    
    if( $self->is_null ){
        $sql .= " NULL ";
    }
    else{
        $sql .= " NOT NULL ";   
    }
    
    my $default = $self->default;
    if( defined $default && $self->type =~ /varchar/i ){
        $default = "\"$default\"";  # Surround default in quotes
    }
    
    if( $self->is_null ){
        if( defined $self->default){
            $sql .= " DEFAULT $default" if defined $self->default;
        }
        else{
            $sql .= " DEFAULT NULL ";
        }
    }
    else{
        $sql .= "DEFAULT $default" if defined $self->default;
    }
    $sql .= "AUTO_INCREMENT " if $self->is_autoinc;
    
    return $sql;
}

1;
