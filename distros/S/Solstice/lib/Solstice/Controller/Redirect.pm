package Solstice::Controller::Redirect;

# $Id: $

=head1 NAME

Solstice::Controller::Redirect - The controller for Redirect

=head1 SYNOPSIS

  # See L<Solstice::Controller> for usage.

=head1 DESCRIPTION

This is the controller for the page Redirect

The canonical solstice redirector.  Give it a URL, users will be redirected to it.

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller);

use Solstice::CGI;
use Solstice::View::Redirect;

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut


=item new($url)

Constructor.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self;
}


=item getView()

Creates the view object for Redirect.

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::Redirect->new($self->getModel());


    return $view;
}


=item validPreConditions()

=cut

sub validPreConditions {
    my $self = shift;

    return TRUE if defined $self->getModel();
    return FALSE;
}


=item revert()

=cut

sub revert {
    my $self = shift;
    return TRUE;
}


=item update()

=cut

sub update {
    my $self = shift;

    return TRUE;
}


=item validate()

=cut

sub validate {
    my $self = shift;

    return $self->processConstraints();
}


=item commit()

=cut

sub commit {
    my $self = shift;

    return TRUE;
}


1;
__END__

=back

=head1 AUTHOR

Catalyst Research & Development Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: $

=head1 SEE ALSO

L<Solstice::Controller>,
L<Solstice::View::Redirect>,
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
