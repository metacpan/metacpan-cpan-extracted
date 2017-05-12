package Solstice::Factory;

=head1 NAME

Solstice::Factory - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice);

use Solstice::List;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item createByID($id)

=cut

sub createByID {
    my $self = shift;
    my $id = shift;
    return $self->createByIDs([$id])->shift();
}

=item createByIDs(\@list)

=cut

sub createByIDs {
    my $self = shift;
    my $array_ref = shift;
    warn((ref $self).'->createByIDs(): Not implemented');
    return Solstice::List->new();
}

=item createByOwner($person)

=cut

sub createByOwner {
    my $self = shift;
    my $person = shift;
    warn(ref $self.'->createByOwner(): Not implemented');
    return Solstice::List->new();
}

=item createHashByIDs(\@list)

=cut

sub createHashByIDs {
    my $self = shift;
    my $ids  = shift || [];
    my %hash = ();

    return \%hash unless @$ids;

    my $iterator = $self->createByIDs($ids)->iterator();
    while (my $obj = $iterator->next()) {
        $hash{$obj->getID()} = $obj;
    }
    return \%hash;
}

1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 597 $

=head1 SEE ALSO

L<Solstice::List|Solstice::List>.

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
