package t::odea::Maybe;

use Moo;
use MooX::ValidateSubs;
use Types::Standard qw/Str ArrayRef HashRef Split/;

validate_subs (
	[qw/hello_hash hello_hashref/] => {
		params => {
			one   => [ Str, sub { 'I Have a Default Value' } ],
			two   => [ ArrayRef ],
			three => [ HashRef ],
		},
	},
	[qw/a_list a_single_arrayref/] => {
		params => [ [Str], [ArrayRef], [HashRef] ],
	},
	named => {
		params => [ [Str, sub { 'one' }], [Str, sub { 'two' }], [Str, sub { 'three' }] ],
	},
	hnamed => {
		params => [ [Str, sub { 'one' }], [Str, sub { 'two' }], [HashRef, sub { { three => 'four' } }] ],
	},
	anamed => {
		params => [ [Str, sub { 'one' }], [Str, sub { 'two' }], [ArrayRef, sub { [ qw/three four/ ] }] ],
	},
	keys => {
		params => {
			one   => [ Str, sub { 'one' } ],
			two   => [ Str, sub { 'two' } ],
			three => [ Str, sub { 'three' } ],
		},
		keys => [qw/three two one/]
	},
	coe => {
		params => [ [(ArrayRef)->plus_coercions(Split[qr/\s/])] ],
	}
);

sub coe {
	my ($self, $args) = @_;
	return $_[1];
}

sub hello_hash {
	my ($self, %args) = @_;

	$args{four} = 'd';
	return %args;
}

sub hello_hashref {
	my ($self, $args) = @_;

	$args->{four} = 'd';
	return $args;
}

sub keys {
	my ($self, @args) = @_;
	return @args;
}

sub a_list {
	my ($self, @args) = @_;	
	return @args;
}

sub named {
	my ($self, @args) = @_;	
	return @args;
}

sub hnamed {
	my ($self, @args) = @_;	
	return @args;
}

sub anamed {
	my ($self, @args) = @_;	
	return @args;
}

sub a_single_arrayref {
	my ($self, $args) = @_;	
	return $args;
}

sub okay_test {
	my ($self) = shift;
	my ($one, $two, $three) = $self->a_list( 'a', ['b'], { four => 'ahh' } );
	return ($one, $two, $three);
}


1;
