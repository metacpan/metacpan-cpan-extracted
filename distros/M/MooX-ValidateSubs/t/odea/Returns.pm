package t::odea::Returns;

use Moo;
use MooX::ValidateSubs;
use Types::Standard qw/Str ArrayRef HashRef/;

validate_subs (
    [qw/hello_hash hello_hashref/] => {
        returns => {
            one   => [ Str, sub { 'I Have a Default Value' } ],
            two   => [ ArrayRef ],
            three => [ HashRef ],
        	four  => [ Str ],
		},
    },
    [qw/a_list a_single_arrayref/] => {
        returns => [ [Str], [ArrayRef], [HashRef], [Str] ],
    },
);

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

sub a_list {
    my ($self, @args) = @_;    
 	push @args, 'd';
	return @args;
}

sub a_single_arrayref {
    my ($self, $args) = @_;    
	push @{ $args }, 'd';
	return $args;
}

sub okay_test {
    my ($self) = shift;
    my ($one, $two, $three, $four) = $self->a_list( 'a', ['b'], { four => 'ahh' } );
    return ($one, $two, $three, $four);
}

1;
