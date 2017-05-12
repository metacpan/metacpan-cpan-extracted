package Template::Jade::BufferedIO;
use strict;
use warnings FATAL => 'all';

use feature ':5.12';

use Moose::Role;

has '_buffer' => (
	isa       => 'ArrayRef[Str]'
	, is      => 'rw'
	, default => sub { [] }
	, traits  => ['Array']
	, handles => {
		'_buffer_length'   => 'count'
		, '_buffer_clear'  => 'clear'
		, '_buffer_shift'  => 'shift'
		, '_buffer_push'   => 'push'
	}
);

has 'fh_input' => (
	isa  => 'FileHandle'
	, is => 'ro'
	, required => 0
	, lazy => 1
	, default => sub {
		my $self = shift;
		open(my $fh_input, '<', $self->filename ) or die $!;
		$fh_input;
	}
);

has 'filename' => (
	isa => 'Str'
	, is => 'ro'
	, required => 0
	, initializer => sub {
		my ( $self, $value, $set, $attr ) = @_;
		if ( -e $value ) {
			$set->( $value );
		}
		elsif ( -e "$value.jade" ) {
			$set->( "$value.jade" );
		}
		else {
			die "Can not open file $value for processing\n";
		}
	}
);

sub _readline {
	state $counter = 0;
	my $self = shift;
	if ( $self->_buffer_length ) {
		return $self->_buffer_shift;
	}
	else {
		my $fh = $self->fh_input;
		if ( not eof $fh ) {
			my $line = readline $fh;
			chomp $line;
			return $line;
		}
	}
}

1;
