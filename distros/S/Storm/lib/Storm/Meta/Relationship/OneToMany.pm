package Storm::Meta::Relationship::OneToMany;
{
  $Storm::Meta::Relationship::OneToMany::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;

extends 'Storm::Meta::Relationship';
use Storm::Types qw( StormForeignKeyConstraintValue );

has 'match_on' => (
    is       => 'rw' ,
    isa      => 'Maybe[Str]',
    writer   => '_set_match_on'  ,
);

has 'on_delete' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'RESTRICT',
);

has 'on_update' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'CASCADE',
);


sub _iter_method {
    my ( $self, $instance ) = @_;
    
    my $orm = $instance->orm;
    confess "$instance must exist in the database" if ! $orm;
    
    my $foreign_key = $self->match_on ? $self->match_on : $self->associated_class->meta->primary_key->column->name;
   
    my $query = $orm->select_query($self->foreign_class);
    $query->where("`$foreign_key`", '=', $self->associated_class->meta->primary_key->get_value($instance));
    $query->results;
}


sub _build_handle_methods {
    my ( $self ) = @_;
    my %methods;
    
    for my $method_name ($self->_handles) {
        my $action = $self->get_handle($method_name);
        my $code_ref;
        if ($action eq 'iter'  ) { $code_ref = sub { $self->_iter_method(@_) } }
        else {
            confess "could not create handle $method_name because $action is not a valid action"
        }
        
        # wrap the method
        my $wrapped_method = $self->associated_class->meta->method_metaclass->wrap(
            name         => $method_name,
            package_name => $self->associated_class,
            body         => $code_ref,
        );
        
        $methods{$method_name} = $wrapped_method;
    }
    
    
    return \%methods;
}


no Moose;
__PACKAGE__->meta()->make_immutable();
1;
