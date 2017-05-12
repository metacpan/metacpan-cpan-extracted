package t::odea::Returns;

use Moo;
use MooX::ValidateSubs;
use Types::Standard qw/Str ArrayRef HashRef/;

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
