package Storm::Meta::Relationship;
{
  $Storm::Meta::Relationship::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( HashRef );

has name =>(
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'associated_class' =>(
    is => 'rw',
    isa => 'ClassName',
    writer => '_set_associated_class',
    clearer => '_clear_associated_class',
    init_arg => undef,
);

has 'foreign_class' => (
    is       => 'rw',
    isa      => 'ClassName',
    writer   => '_set_foreign_class'   ,
    weak_ref => 1,
);

has 'handles' => (
    is => 'ro',
    isa => HashRef,
    traits => [qw( Hash )],
    default => sub { { } },
    handles => {
        get_handle  => 'get',
        _set_handle => 'set',
        _handles    => 'keys',
    }
);

has '_handle_methods' => (
    is => 'ro',
    isa => HashRef,
    builder => '_build_handle_methods' ,
    lazy => 1,
);



sub attach_to_class {
    my ( $self, $meta ) = @_;
    my $class = $meta->name;
    
    $self->_set_associated_class($class);

    my $methods = $self->_handle_methods;

    for my $method_name(keys %$methods) {
        $meta->add_method($method_name => $methods->{$method_name});
    }
    
    $meta->_add_relationship( $self->name, $self );
}

sub detach_from_class {
    my ( $self, $meta ) = @_;
    return unless $self->associated_class();
    
    my $methods = $self->_handle_methods;

    for my $method_name(keys %$methods) {
        $self->associated_class->meta->remove_method($method_name);
    }

    $self->_clear_associated_class();
    
    $meta->_remove_relationship( $self->name );
}



1;
