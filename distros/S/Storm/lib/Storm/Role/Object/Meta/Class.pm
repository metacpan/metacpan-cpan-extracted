package Storm::Role::Object::Meta::Class;
{
  $Storm::Role::Object::Meta::Class::VERSION = '0.240';
}

use Moose::Role;
use Storm::Meta::Relationship::ManyToMany;
use Storm::Meta::Relationship::OneToMany;
use Storm::Meta::Table;


use Storm::Types qw( SchemaTable StormMetaRelationship );
use Storm::Meta::Attribute::Trait::PrimaryKey;
use MooseX::Types::Moose qw( HashRef Undef );


has storm_table => (
    is        => 'rw' ,
    isa       => SchemaTable|Undef,
    lazy_build => 1,
    coerce    => 1,
);

sub _build_storm_table {
    my ( $self ) = @_;
    
    my $table;
    for my $class ( ($self->class_precedence_list)[0..-1] ) {
        my $meta = $class->meta;
        if ( $meta->can('storm_table') && $meta->has_storm_table ) {
            $table = $meta->storm_table;
            last if $table;
        }
    }
}


# TODO: Cache this function, maybe rename it?
sub primary_key {
    my ( $self ) = @_;
    for my $att ( $self->get_all_attributes ) {
        return $att if $att->does( 'PrimaryKey' );
    }
}

has 'relationships' => (
    is => 'rw',
    isa => HashRef,
    traits => [qw( Hash )],
    handles => {
        '_add_relationship' => 'set',
        'get_relationship' => 'get',
        'get_relationship_list' => 'keys',
        '_remove_relationship' => 'delete',
    }
);

after 'add_attribute' => sub {
    my ( $meta, $name ) = @_;
    return if $name =~ /^\+/;
    
    my $att = blessed $name ? $name : $meta->get_attribute( $name );    
    $att->column->set_table( $meta->storm_table ) if $att->column && $meta->storm_table;
};

sub many_to_many {
    my ( $self, %params ) = @_;
    my $relationship = Storm::Meta::Relationship::ManyToMany->new( %params );
    $relationship->attach_to_class( $self );
}

sub one_to_many {
    my ( $self, %params ) = @_;
    my $relationship = Storm::Meta::Relationship::OneToMany->new( %params );
    $relationship->attach_to_class( $self );
}

sub add_has_many {
    my $meta = shift;
    my %p    = @_;
    
    warn q[Storm::Role::Object::Meta::add_has_many is deprecated - ] .
    q[use Storm::Role::Object::Meta::one_to_many or ] .
    q[Storm::Role::Object::Meta::many_to_many instead.];
    
    my $has_many = exists $p{junction_table} ?
    Storm::Meta::Relationship::ManyToMany->new(%p) :
    Storm::Meta::Relationship::OneToMany->new(%p) ;

    $has_many->attach_to_class($meta);
}

1;