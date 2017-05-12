package SIAM::AccessScope;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::ScopeMember;

=head1 NAME

SIAM::AccessScope - access scope object class

=head1 SYNOPSIS


=head1 INSTANCE METHODS

=head2 new

  $scope = new SIAM::AccessScope($driver, {'siam.object.id' => $id})

Instantiates a new object. The following object IDs are predefined and
are not fetched from the driver:

=over 4

=item * SIAM.SCOPE.ALL.CONTRACTS

The access scope with the name I<AllContracts>. All contract objects are
implicitly included in it.

=item * SIAM.SCOPE.ALL.ATTRIBUTES

The access scope with the name I<AllAttributes>. All attribute names are
implicitly in it.

=back

=cut

my %match_all_id =
    ('SIAM.SCOPE.ALL.CONTRACTS' =>
     {
      'siam.scope.name' => 'AllContracts',
      'siam.scope.applies_to' => 'SIAM::Contract',
     },
     
     'SIAM.SCOPE.ALL.ATTRIBUTES' =>
     {
      'siam.scope.name' => 'AllAttributes',
      'siam.scope.applies_to' => 'SIAM::Attribute',
     },
    );


sub new
{
    my $class = shift;
    my $driver = shift;
    my $id = shift;
    
    if( defined($id) and defined($match_all_id{$id}) )
    {
        my $self = {};
        bless $self, $class;

        $self->{'_attr'} = {'siam.object.id' => $id};
        while( my($key, $val) = each %{$match_all_id{$id}} )
        {
            $self->{'_attr'}{$key} = $val;
        }

        return $self;
    }
    else
    {
        return $class->SUPER::new( $driver, $id );
    }
}



=head2 match_object

Expects an object as an argument. Returns true if the object matches the scope.

=cut


sub match_object
{
    my $self = shift;
    my $obj = shift;

    # siam.scope.applies_to should match the object class
    if( $obj->objclass ne $self->attr('siam.scope.applies_to') )
    {
        return undef;
    }

    # check if we are one of the predefined scopes
    if( defined($match_all_id{$self->id}) )
    {
        return 1;
    }

    # check if object ID matches one of our members
    my $members = $self->get_contained_objects
        ('SIAM::ScopeMember',
         {'match_attribute' => ['siam.scmember.object_id', [$obj->id()]]});

    if( scalar(@{$members}) > 0 )
    {
        return 1;
    }
    
    return undef;
}



=head2 get_object_ids

Returns arrayref with all object IDs to which this scope's members point to.

=cut


sub get_object_ids
{
    my $self = shift;
    
    my $members = $self->get_contained_objects('SIAM::ScopeMember');

    my $ret = [];
    foreach my $member (@{$members})
    {
        push(@{$ret}, $member->points_to);
    }
    return $ret;
}
            



=head1 CLASS METHODS


=head2 matches_all

Takes an ID of an SIAM::AccessScope object and the object class.
Returns true if it's a match-all scope for a given class.

=cut


sub matches_all
{
    my $class = shift;
    my $id = shift;
    my $objclass = shift;

    return( defined($match_all_id{$id}) and
            $match_all_id{$id}{'siam.scope.applies_to'} eq $objclass );
}



# mandatory attributes

my $mandatory_attributes =
    [ 'siam.scope.name',
      'siam.scope.applies_to' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::ScopeMember->_manifest_attributes() });

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
