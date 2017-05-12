package Test::MySpec;

use base qw/Peco::Spec/;

sub new {
    my ( $class, @spec ) = @_;
    bless {
        spec => \@spec,
    }, $class;
}

sub class { ref( $_[0] ) }

sub instance {
    my ( $self, $cont, $key ) = @_;
    $self->{foo} = $cont->service('foo');
    $self;
}

1;
