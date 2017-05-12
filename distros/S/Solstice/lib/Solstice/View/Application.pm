package Solstice::View::Application;

# $Id: Application.pm 3385 2006-05-17 23:16:52Z mcrawfor $

=head1 NAME

Solstice::View::Application - The application wide view (boilerplate) for a Solstice application. 

=head1 SYNOPSIS

  use Solstice::View::Application;

  my $app_view = new Solstice::View::Application();
  my $screen = "";
  $app_view->paint($screen);

=head1 DESCRIPTION

The main application view for Solstice.  This view is simply an HTML framework
to build the Solstice application on.  It combines the views of other Solstice 
components to create the Solstice look and feel.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View);

use Solstice::Application;
use Solstice::NamespaceService;
use Solstice::Server;
use Solstice::Session;
use Solstice::StringLibrary qw(unrender);

use constant TEMPLATE => 'boilerplate/document.html';

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3385 $' =~ /^\$Revision:\s*([\d.]*)/);

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

    $self->_setTemplatePath('templates');
    $self->_setTemplate(TEMPLATE);

    return $self;
}

sub setEscapeFrames {
    my $self = shift;
    $self->{'_escape_frames'} = shift;
}

sub getEscapeFrames {
    my $self = shift;
    return $self->{'_escape_frames'};
}

=back

=head2 Private Methods

=over 4

=item _getTemplateParams()

=cut

sub _getTemplateParams {
    my $self = shift;

    my $ns_service      = Solstice::NamespaceService->new();
    my $include_service = $self->getIncludeService();
    my $onload_service  = $self->getOnloadService();
    my $app_config = $self->getConfigService($ns_service->getAppNamespace());
    my $app_virtual_root = $app_config->getAppURL();
    my $session = Solstice::Session->new();

    # Add the current application includes
    $include_service->addApplicationIncludes($ns_service->getAppNamespace());
    
    my %params = $self->processChildViews();

    # Process the javascript includes 
    my @js_includes = map { {src => $_} } @{$include_service->getJavascriptIncludes()};
    
    # Process the css includes
    my @css_includes = map { {src => $_} } @{$include_service->getCSSIncludes()};

    # Onload events
    if ($session->getSubsessionID()) {
        $onload_service->addEvent(
            'Solstice.Remote.run(\'Solstice\', \'subsession_check\', {\'subsession\': solstice_subsession, \'chain_id\': solstice_subsession_chain })'
        );
    }
    my @onload_events = map { {event => $_} } @{$onload_service->getEvents()};

    my $server = Solstice::Server->new();

    return {
        %params,
        document_lang       => 'en', 
        document_title      => $self->getDocumentTitle(), 
        document_base       => $self->getBaseURL(), 
        document_script     => \@js_includes,
        document_stylesheet => \@css_includes,
        development_mode    => $app_config->getDevelopmentMode() || FALSE,
        onload_events       => \@onload_events,
        session_app_key     => $self->getSessionAppKey(),
        subsession_id       => $session->getSubsessionID(),
        chain_id            => $session->getSubsessionChainID(),
        uri                 => $server->getURI(), 
        escape_frames       => $self->getEscapeFrames(),
        app_path            => $app_virtual_root,
    };
}


=item setDocumentTitle($document_title)

Set the HTML 'title' tag value to C<$document_title>.

=cut

sub setDocumentTitle {
    my $self = shift;
    $self->{'_document_title'} = shift;
}

=item getDocumentTitle()

Returns the HTML 'title' tag value.

=cut

sub getDocumentTitle {
    my $self = shift;
    return unrender($self->getIncludeService()->getPageTitle() || $self->{'_document_title'});
}



sub setSessionAppKey {
    my $self = shift;
    $self->{'_session_app_key'} = shift;
}


sub getSessionAppKey {
    my $self = shift;
    return $self->{'_session_app_key'};
}


1;

__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>,
L<Solstice::Application|Solstice::Application>,
L<Solstice::OnloadService|Solstice::OnloadService>,
L<Solstice::IncludeService|Solstice::IncludeService>,

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3385 $



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
