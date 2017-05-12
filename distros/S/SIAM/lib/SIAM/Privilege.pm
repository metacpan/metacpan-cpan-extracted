package SIAM::Privilege;

use warnings;
use strict;

use base 'SIAM::Object';

use SIAM::AccessScope;


=head1 NAME

SIAM::Privilege - Privilege object class

=head1 SYNOPSIS


=head1 METHODS


=head2 scope_id

Retrurns the value of C<siam.privilege.access_scope_id> attribute.

=cut

sub scope_id
{
    my $self = shift;
    return $self->attr('siam.privilege.access_scope_id');
}


=head2 match_object

Expects an object as an argument. Returns true if the object matches the
related scope.

=cut


sub match_object
{
    my $self = shift;
    my $obj = shift;

    my $scope = new SIAM::AccessScope($self->_driver, $self->scope_id);    
    return $scope->match_object($obj);
}



=head2 matches_all

Takes an object class. Returns true if the privilege is associated with
a match-all scope for a given class.

=cut


sub matches_all
{
    my $self = shift;
    my $objclass = shift;

    return SIAM::AccessScope->matches_all
        ($self->attr('siam.privilege.access_scope_id'), $objclass);
}


# mandatory attributes

my $mandatory_attributes =
    [ 'siam.privilege.access_scope_id',
      'siam.privilege.type' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}

sub _manifest_attributes
{
    return $mandatory_attributes;
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
