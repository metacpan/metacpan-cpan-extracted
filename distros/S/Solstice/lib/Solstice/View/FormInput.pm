package Solstice::View::FormInput;

# $Id: FormInput.pm 63 2006-06-19 22:51:42Z jlaney $

=head1 NAME

Solstice::View::FormInput -

=head1 SYNOPSIS

=head1 DESCRIPTION

Superclass for the Solstice FormInput views.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View);

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 63 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=item setName($str)

=cut

sub setName {
    my $self = shift;
    $self->{'_name'} = shift;
}

=item getName()

=cut

sub getName {
    my $self = shift;
    return $self->{'_name'};
}

=item setClientAction($str)

=cut

sub setClientAction {
    my $self = shift;
    $self->{'_client_action'} = shift;
}

=item getClientAction()

=cut

sub getClientAction {
    my $self = shift;
    return $self->{'_client_action'};
}

=item setClassName($str)

=cut

sub setClassName {
    my $self = shift;
    $self->{'_class_name'} = shift;
}

=item getClassName()

=cut

sub getClassName {
    my $self = shift;
    return $self->{'_class_name'};
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>.

=head1 AUTHOR

Solstice Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 63 $

=head1 SEE ALSO

L<perl>.

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
