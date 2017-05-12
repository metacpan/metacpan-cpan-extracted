package Storm::LiveObjects;
{
  $Storm::LiveObjects::VERSION = '0.240';
}
use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Storm::LiveObjects::Scope;
use Scalar::Util qw(weaken refaddr);

use Storm::Types qw( StormLiveObjectScope );
use MooseX::Types::Moose qw( HashRef );


has '_objects' => (
    is  => 'ro',
    isa => HashRef,
    default => sub { { } },
);

has 'current_scope' => (
    is => 'ro',
    isa => StormLiveObjectScope,
    writer  => 'set_current_scope'     ,
    clearer => 'clear_current_scope'   ,
    weak_ref => 1,
);


sub get_object {
    my ( $self, $class, $key ) = @_;
    return $self->_objects->{$class}{$key};
}

sub has_object {
    my ( $self, $class, $key ) = @_;
    return $self->_objects->{$class}{$key} ? 1 : 0;
}
sub remove {
    my ( $self, @objects ) = @_;
    my $scope = $self->current_scope or confess "no open live object scope";
    
    for my $object (@objects) {
        
        confess $object, " is not an object" if ! blessed $object;
        confess $object, " is not a Storm enabled object" if ! $object->does( 'Storm::Role::Object' );
        
        my $class = ref $object;
        my $identifier = $object->meta->primary_key->get_value($object);
        
        # $$object = undef;
        
        # throw exception if no identifier
        confess "you must set the primary key for ", $object, " before removing it from the live objects cache"
            if ! $identifier;
        delete $self->_objects->{$class}{$identifier};
    }
}

sub new_scope {
    my ( $self ) = @_;
    my $parent = $self->current_scope;

    my $scope = Storm::LiveObjects::Scope->new(
        ( $parent ? ( parent => $parent ) : () ),
        live_objects => $self,
    );

    $self->set_current_scope($scope);

    return $scope;
}


sub insert {
    my ( $self, @objects ) = @_;
    my $scope = $self->current_scope or confess "no open live object scope";
    
    for my $object (@objects) {
        
        confess $object, " is not an object" if ! blessed $object;
        confess $object, " is not a Storm enabled object" if ! $object->does('Storm::Role::Object');
        
        my $class = ref $object;
        my $identifier = $object->meta->primary_key->get_value($object);
        
        # throw exception if no identifier
        confess "you must set the primary key for ", $object, " before inserting into the live objects cache"
            if ! $identifier;
       
        # throw exception if already registered
        confess $object, "is already registered" if $self->is_registered( $object );
        
        # weaken
        $self->_objects->{$class}{$identifier} = $object;
        weaken($self->_objects->{$class}{$identifier});
        
        
        $scope->push($object);
    }
}

sub clear {
    my ( $self ) = @_;
    %{ $self->_objects } = ();
}

sub is_registered {
    my ( $self, $object ) = @_;
    my $class = ref $object;
    my $identifier = $object->meta->primary_key->get_value($object);
    return undef if ! defined $identifier;
    
    $self->_objects->{$class}{$identifier} &&
    refaddr $self->_objects->{$class}{$identifier} == refaddr $object ? 1 : 0 ;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;