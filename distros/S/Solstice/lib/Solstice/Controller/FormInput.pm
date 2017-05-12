package Solstice::Controller::FormInput;

# $Id: FormInput.pm 25 2006-01-14 00:50:12Z jlaney $

=head1 NAME

Solstice::Controller::FormInput - Superclass for all of the Solstice-provided convienience widgets

=head1 SYNOPSIS

=head1 DESCRIPTION

A superclass for the Solstice FormInput controllers

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller);

use constant TRUE  => 1;
use constant FALSE => 0;

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=item new($model)

Constructor.

=cut

sub new {
    my $class = shift;
    return $class->SUPER::new(@_);
}

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

=item setIsRequired($bool)

=cut

sub setIsRequired {
    my $self = shift;
    $self->{'_is_required'} = shift;
}

=item getIsRequired()

=cut

sub getIsRequired {
    my $self = shift;
    return $self->{'_is_required'};
}


1;
__END__

=back

=head1 AUTHOR

Educational Technology Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 25 $

=head1 SEE ALSO

L<FCKEditor::Controller>,
L<FCKEditor::View::Editor>,
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
