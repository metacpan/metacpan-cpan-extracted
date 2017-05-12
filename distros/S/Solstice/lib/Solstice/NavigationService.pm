package Solstice::NavigationService;

# $Id: NavigationService.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::NavigationService - A service for all types of navigation up a controller chain.

=head1 SYNOPSIS

  use Solstice::NavigationService;
  
  my $navigation_service = Solstice::NavigationService->new();
  $navigation_service->setView($view);


=head1 DESCRIPTION

This is a service for putting app specific nav(any view really) at the top of a screen.  

=cut

use 5.006_000;
use strict;
use warnings;

use constant APP_NAVIGATION => '_app_navigation_';
use constant BREADCRUMB_NAVIGATION => '_breadcrumb_navigation_';

use Solstice::Service;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);
our @ISA = qw(Solstice::Service);

=head2 Superclass

L<Solstice::Service|Solstice::Service>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Creates a new Solstice::NavigationService, tied to an Apache thread wide base of navigation.

=cut

sub new {
    my $obj = shift;
    return $obj->SUPER::new(@_);
}

=item setView($view)

Sets the view to the service. 

=cut

sub setView {
    my $self = shift;
    my $view = shift;

    $self->set(APP_NAVIGATION, $view);
    return 1;
}

sub getView {
    my $self = shift;
    return $self->get(APP_NAVIGATION);
}

sub setBreadcrumbView {
    my $self = shift;
    my $view = shift;

    $self->set(BREADCRUMB_NAVIGATION, $view);
    return 1;
}

sub getBreadcrumbView {
    my $self = shift;
    return $self->get(BREADCRUMB_NAVIGATION);
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Service|Solstice::Service>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $



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
