package Solstice::View::FormInput::TextArea;

# $Id: TextArea.pm 63 2006-06-19 22:51:42Z jlaney $

=head1 NAME

Solstice::View::FormInput::TextArea - A view of an html <textarea> element

=head1 SYNOPSIS

    use Solstice::View::FormInput::TextArea;

    my $content = 'A string containing <i>content</i>.';

    my $view = Solstice::View::FormInput::TextArea->new($content);
    $view->setName('mytextbox');
    $view->setWidth('90%');  # a percentage or an integer representing pixels
    $view->setHeight(450);   # a percentage or an integer representing pixels
    $view->setIsResizable(1);
    
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View::FormInput);

use Solstice::NamespaceService;
use Solstice::PreferenceService;
use Solstice::StringLibrary qw(unrender);

use constant TRUE  => 1;
use constant FALSE => 0;
use constant WIDTH  => '100%';
use constant HEIGHT => '250';

our $template = 'form_input/textarea.html';

our ($VERSION) = ('$Revision: 63 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View::FormInput|Solstice::View::FormInput>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_setTemplatePath('templates');

    return $self;
}

=item setWidth($int)

=cut

sub setWidth {
    my $self = shift;
    $self->{'_width'} = shift;
}

=item getWidth()

=cut

sub getWidth {
    my $self = shift;
    return $self->{'_width'};
}

=item setHeight($int)

=cut

sub setHeight {
    my $self = shift;
    $self->{'_height'} = shift;
}

=item getHeight()

=cut

sub getHeight {
    my $self = shift;
    return $self->{'_height'};
}

=item setIsResizable($bool)

=cut

sub setIsResizable {
    my $self = shift;
    $self->{'_is_resizable'} = shift;
}

=item getIsResizable()

=cut

sub getIsResizable {
    my $self = shift;
    return $self->{'_is_resizable'};
}

=item setFocusEditor($bool)

=cut

sub setFocusEditor {
    my $self = shift;
    $self->{'_focus_editor'} = shift;
}

=item getFocusEditor()

=cut

sub getFocusEditor {
    my $self = shift;
    return $self->{'_focus_editor'};
}

=item setConfigPath($str)

=cut

sub setConfigPath {
    my $self = shift;
    $self->{'_config_path'} = shift;
}

=item getConfigPath()

=cut

sub getConfigPath {
    my $self = shift;
    return $self->{'_config_path'};
}

=item setSkinPath($str)

=cut

sub setSkinPath {
    my $self = shift;
    $self->{'_skin_path'} = shift;
}

=item getSkinPath()

=cut

sub getSkinPath {
    my $self = shift;
    return $self->{'_skin_path'};
}

=item setPluginsPath($str)

=cut

sub setPluginsPath {
    my $self = shift;
    $self->{'_plugins_path'} = shift;
}

=item getPluginsPath()

=cut

sub getPluginsPath {
    my $self = shift;
    return $self->{'_plugins_path'};
}

=item setToolbarSet($str)

=cut

sub setToolbarSet {
    my $self = shift;
    $self->{'_toolbar_set'} = shift;
}

=item getToolbarSet()

=cut

sub getToolbarSet {
    my $self = shift;
    return $self->{'_toolbar_set'};
}

=item generateParams()

=cut

sub generateParams {
    my $self = shift;

    my $width  = $self->getWidth()  || WIDTH;
    my $height = $self->getHeight() || HEIGHT;
    
    $self->setParam('name', $self->getName());    
    $self->setParam('height', ($height =~ /^\d+%$/) ? $height : $height.'px');    
    $self->setParam('width', ($width =~ /^\d+%$/) ? $width : $width.'px');
    $self->setParam('content', unrender($self->getModel()));

    $self->getIncludeService()->addIncludedFile({
        file => 'javascript/textarea.js',
        type => 'text/javascript',
    });

    return TRUE;
}

=item generateRTESwitchParams()

Generate params for buttons to allow switching between plain text and RTE text areas. This is used by subclasses that support a RTE.

=cut

sub generateRTESwitchParams {
    my $self = shift;

    # Don't set any params if config doesn't allow switching
    return TRUE unless $self->getConfigService()->get('allow_rte_switching');

    my $button_service = $self->getButtonService();

    # Scroll to the correct textarea
    my $current_target = $button_service->getAttribute('scroll_textarea') || '';
    my $scroll_target  = $self->getName().'_container';
    if ($current_target eq $scroll_target) {
        $self->getOnloadService()->setScrollTarget($scroll_target);
    }

    my $use_rte = $self->isRichTextEnabled();

    my $rte_switch = $button_service->makeButton({
        lang_key         => $use_rte ? 'turn_off_rte' : 'turn_on_rte',
        action           => '__set_preference__',
        attributes       => {
            scroll_textarea => $scroll_target,
        },
        preference_key   => 'use_plaintext',
        preference_value => $use_rte ? TRUE : FALSE,
        client_action    => 'window.onbeforeunload = null; true;',
    });

    $self->setParam('using_plaintext', $use_rte ? FALSE : TRUE);
    $self->setParam('rte_switch', $rte_switch->getTextLink());

    return TRUE;
}

=item isRichTextEnabled()

Determines if user is seeing plaintext or rte editor, depending on an application-level preference.

=cut

sub isRichTextEnabled {
    my $self = shift;

    return TRUE unless $self->getConfigService()->get('allow_rte_switching');

    my $preference_service = Solstice::PreferenceService->new();
    my $ns_service = Solstice::NamespaceService->new();
    $preference_service->setNamespace($ns_service->getAppNamespace());

    return $preference_service->getPreference('use_plaintext') ? FALSE : TRUE;
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
