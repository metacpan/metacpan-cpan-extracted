package SIAM::User;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::Privilege;
use SIAM::AccessScope;

=head1 NAME

SIAM::User - User object class

=head1 SYNOPSIS

   my $user = $siam->get_user($uid);


=head1 METHODS

=head2 has_privilege

  $user->has_privilege('ViewContract', $contract)

Expects a privilege string and an object. Returns true if the object matches
the privilege

=cut

sub has_privilege
{
    my $self = shift;
    my $priv = shift;
    my $obj = shift;

    my $privileges = $self->get_contained_objects
        ('SIAM::Privilege',
         {'match_attribute' => ['siam.privilege.type', [$priv]]});

    foreach my $privilege (@{$privileges})
    {
        if( $privilege->match_object($obj) )
        {
            return 1;
        }        
    }

    return undef;
}



=head2 get_objects_by_privilege

  $user->get_objects_by_privilege('ViewContract', 'SIAM::Contract', $siam)

Expects 3 arguments: privilege string; object class; and a container object.
Returns arrayref with all matching objects.

=cut

sub get_objects_by_privilege
{
    my $self = shift;
    my $priv = shift;
    my $objclass = shift;
    my $objcontainer = shift;
    
    my $privileges = $self->get_contained_objects
        ('SIAM::Privilege',
         {'match_attribute' => ['siam.privilege.type', [$priv]]});

    # Driver may return the same scope twice, so we keep track of which scopes
    # we've already seen
    
    my @scopes;
    my %scopes_seen;
    
    foreach my $privilege (@{$privileges})
    {
        if( $privilege->matches_all($objclass) )
        {
            return $objcontainer->get_contained_objects($objclass);
        }
        else
        {
            my $id = $privilege->scope_id;
            if( not $scopes_seen{$id} )
            {
                push(@scopes,
                     new SIAM::AccessScope($self->_driver, $id));
            }
        }
    }

    # Scopes may overlap, so we put the object IDs in a hash
    my %object_ids;
    foreach my $scope (@scopes)
    {
        my $ids = $scope->get_object_ids();
        foreach my $id (@{$ids})
        {
            $object_ids{$id} = 1;
        }
    }

    # Retrieve the matching objects

    my $ret = [];
    foreach my $id ( keys %object_ids )
    {
        push(@{$ret}, $self->instantiate_object($objclass, $id));
    }

    return $ret;
}
    

    





# mandatory attributes

my $mandatory_attributes =
    [ 'siam.user.uid' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::Privilege->_manifest_attributes() });

    return $ret;
}

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
