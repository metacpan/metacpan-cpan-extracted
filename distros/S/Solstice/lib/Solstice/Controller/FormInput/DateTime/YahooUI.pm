package Solstice::Controller::FormInput::DateTime::YahooUI;

# $Id: Editor.pm 3155 2006-02-21 20:08:18Z mcrawfor $

=head1 NAME

JSCalendar::Controller::DateTime::Editor

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use 5.006_000;

use base qw(Solstice::Controller::FormInput::DateTime);

use Solstice::View::FormInput::DateTime::YahooUI;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant PARAM => 'datetime_editor';

our ($VERSION) = ('$Revision: 3155 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Controller::FormInput::DateTime|Solstice::Controller::FormInput::DateTime>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item getView()

=cut

sub getView {
    my $self = shift;

    my $view = Solstice::View::FormInput::DateTime::YahooUI->new($self->getModel());
    $view->setName($self->getName() || PARAM);
    $view->setError($self->getError());
    $view->setShowErrors(defined $self->getShowErrors() ? $self->getShowErrors() : TRUE);
    
    return $view;
}


1;

__END__

=back

=head2 Modules Used

L<Solstice::Controller::FormInput::DateTime|Solstice::Controller::FormInput::DateTime>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3155 $



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
