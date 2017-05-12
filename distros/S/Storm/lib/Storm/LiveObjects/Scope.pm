package Storm::LiveObjects::Scope;
{
  $Storm::LiveObjects::Scope::VERSION = '0.240';
}

use Moose;
use namespace::clean -except => 'meta';

use Storm::Types qw( StormLiveObjects );
use MooseX::Types::Moose qw( ArrayRef );

has objects => (
    isa => ArrayRef,
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        push => 'push',
        objects => 'elements',
        clear => 'clear',
    },
);

has parent => (
    is => 'ro',
    isa => __PACKAGE__,
);

has live_objects => (
    is => 'ro',
    isa => StormLiveObjects,
    required => 1,
);

sub DEMOLISH {
    my $self = shift;

    if ( my $lo = $self->live_objects ) {
        $self->parent ?
        $lo->set_current_scope ( $self->parent ) :
        $lo->clear_current_scope;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Storm::LiveObjects::Scope - Scope helper object

=head1 SYNOPSIS

    {
        my $scope = $storm->new_scope;
        
        ... do work on objects ...
    }

=head1 DESCRIPTION

Live object scopes exist in order to ensure objects don't die too soon if the
only other references to them are weak.

When scopes are destroyed the refcounts of the objects they refer to go down,
and the parent scope is replaced in the live object set.

=head1 METHODS

=over 4

=item push

Adds objects or entries, increasing their reference count.

=item clear

Clears the objects from the scope object.

=back

=head1 SEE ALSO

Modified from code in L<KiokuDB::LiveOBjects::Scope> by Yuval Kogman.

=cut


