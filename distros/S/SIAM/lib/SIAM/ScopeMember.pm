package SIAM::ScopeMember;

use warnings;
use strict;

use base 'SIAM::Object';



=head1 NAME

SIAM::ScopeMember - Scope Member object class

=head1 SYNOPSIS


=head1 METHODS

=head2 points_to

Returns the value of C<siam.scmember.object_id> attribute.

=cut


sub points_to
{
    my $self = shift;
    return $self->attr('siam.scmember.object_id');
}



=head2 match_object

Expects an object as an argument. Returns true if the object matches
this scope member.

=cut


sub match_object
{
    my $self = shift;
    my $obj = shift;

    return ($obj->id eq $self->attr('siam.scmember.object_id'));
}



# mandatory attributes

my $mandatory_attributes =
    [ 'siam.scmember.object_id' ];

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
