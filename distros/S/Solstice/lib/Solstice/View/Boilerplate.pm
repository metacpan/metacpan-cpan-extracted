package Solstice::View::Boilerplate;

=head1 NAME

Solstice::View::Boilerplate - Superclass for boilerplate views.

=cut

use 5.006_000;
use strict;
use warnings;

use Solstice::View::MessageService;

use Solstice::NamespaceService;

use base qw(Solstice::View);

use constant TEMPLATE => 'boilerplate/boiler.html';

=head2 Superclass

L<Solstice::View|Solstice::View>.

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item new($application)

Creates a new Solstice::View::Application object.

=cut

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    $self->_setTemplatePath($self->getConfigService()->getRoot().'/templates');
    $self->_setTemplate(TEMPLATE);
    
    return $self;
}

=item setViewTopNav($bool)

=cut

sub setViewTopNav {
    my $self = shift;
    $self->{'_view_top_nav'} = shift;
}

=item getViewTopNav()

=cut

sub getViewTopNav {
    my $self = shift;
    return $self->{'_view_top_nav'};
}

=back

=head2 Private Methods

=over 4


=item _getTemplateParams()

=cut

sub _getTemplateParams {
    my $self = shift;
    
    my $ns_service = Solstice::NamespaceService->new();
    my $app_name_space = $ns_service->getAppNamespace();

    # Add the messaging pane to the boilerplate if messages need to be shown (still 
    # up to the template to show them though!)
    $self->addChildView('messaging_pane', Solstice::View::MessageService->new());
    
    if (my $nav_view = $self->getNavigationService->new()->getView()) {
        $self->addChildView('application_nav', $nav_view);
    }elsif(defined $app_name_space) {
        my $application_package = $app_name_space.'::Application';
        my $nav_view;
        eval {
            $self->loadModule($application_package);
            $nav_view = $application_package->new()->getNavigationView();
        };
        $self->addChildView('application_nav', $nav_view) if $nav_view;
    }
    
    $self->generateParams();
    my %child_views = $self->processChildViews();
    foreach my $key (%child_views) {
        $self->setParam($key, $child_views{$key});
    }


    # We go through this bit of convolution because we have some subclasses that 
    # never bother to create an app namespace, as they just do a quick redirect 
    # to wherever they want to go.
    my $app_home = '';
    if (defined $app_name_space) {
        my $app_config = $self->getConfigService($ns_service->getAppNamespace());
        $app_home = $app_config->getAppURL() . '/';
    }
    $self->setParam('app_home', $app_home);

    return $self->{'_params'};
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::Configure|Solstice::Configure>,
L<Solstice::View|Solstice::View>,
L<Solstice::Application|Solstice::Application>,
L<Solstice::OnloadService|Solstice::OnloadService>,
L<Solstice::IncludeService|Solstice::IncludeService>,

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2586 $



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
