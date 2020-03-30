package Statistics::Covid::Version;

use 5.006;
use strict;
use warnings;

use parent 'Statistics::Covid::IO::DualBase';

# this is where our DB schema is specified
# edit this file to reflect your table design as well as your $self variables
use Statistics::Covid::Version::Table;

use DateTime;

our $VERSION = '0.23';

# our constructor which calls parent constructor first and then does
# things specific to us, like dates
# create a Data item, either by supplying parameters as a hashref
# of name=>value or as an array which must have as many elements
# as the 'db-columns' items and in this order.
sub	new {
	my ($class, $params) = @_;
	$params = {} unless defined $params;

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = $class->SUPER::new($Statistics::Covid::Version::Table::SCHEMA, $params);
	if( ! defined $self ){ warn "error, call to $class->new() has failed."; return undef }

	return $self
}
# compares 2 objs and returns the "newer"
# which means the one with more up-to-date markers in our case
# as follows:
# returns 1 if self is bigger than input (and probably more up-to-date)
# returns 0 if self is same as input
# returns -1 if input is bigger than self
# we compare only markers, we don't care about any other fields
sub	newer_than {
	my $self = $_[0];
	my $inputObj = $_[1];
	my ($S, $I);

	if( ($S=$self->version()) > ($I=$inputObj->version()) ){ return 1 }
	elsif( $S < $I ){ return -1 }
	return 0 # identical
}
sub	version {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'c'}->{'version'} unless defined $m;
	$self->{'c'}->{'version'} = $m;
	return $m;
}
sub	author_name {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'c'}->{'authorname'} unless defined $m;
	$self->{'c'}->{'authorname'} = $m;
	return $m;
}
sub	author_email {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'c'}->{'authoremail'} unless defined $m;
	$self->{'c'}->{'authoremail'} = $m;
	return $m;
}
sub	make_random_object {
	srand $_[0] if defined $_[0];

	my $random_name = join('', map { chr(ord('a')+int(rand(ord('z')-ord('a')))) } (1..10));
	my $datum_params = {
	'version' => $random_name,
	'authoremail' => 'abc@abc.com',
	'authorname' => 'andreas',
	};
	my $obj = Statistics::Covid::Version->new($datum_params);
	if( ! defined $obj ){ warn "error, call to ".'Statistics::Covid::Version->new()'." has failed."; return undef }
	return $obj
}
sub	toString {
	my $self = $_[0];
	return '['
		.$self->package()
		.'/'
		.$self->version()
		.' '.$self->author_name()
		.' ('.$self->author_email().')'
	. ']'
}
1;
__END__
# end program, below is the POD
