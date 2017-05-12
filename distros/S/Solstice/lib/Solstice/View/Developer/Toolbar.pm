package Solstice::View::Developer::Toolbar;

# $Id: Toolbar.pm 3364 2006-05-05 07:18:21Z jlaney $

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::View);

use Solstice::NamespaceService;

use constant TEMPLATE => 'developer/toolbar.html';

use constant TRUE  => 1;
use constant FALSE => 0;

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    $self->_setTemplate(TEMPLATE); 
    $self->_setTemplatePath('templates');

    return $self;
}

=back

=head2 Private Methods

=over 4

=item _getTemplateParams()

=cut

sub generateParams {
    my $self = shift;

    my $is_dev_mode = $self->getConfigService()->getDevelopmentMode();
    $self->setParam('is_dev_mode', $is_dev_mode);
    $self->setParam('process', $$);
    
    return TRUE unless $is_dev_mode;
   
    
    my $button_service = $self->getButtonService();
    my $preference_service = $self->getPreferenceService(Solstice::NamespaceService->new()->getNamespace());
    
    my $display_wire_frames = $preference_service->getPreference('display_wire_frames');
    my $wire_frames_button = $button_service->makeButton({
        lang_key => $display_wire_frames ? 'hide_wire_frames' : 'display_wire_frames', 
        action   => '__set_preference__',
        preference_key   => 'display_wire_frames',
        preference_value => $display_wire_frames ? FALSE : TRUE,
    });
    $self->setParam('wire_frames_button', $wire_frames_button->getTextLink());
    $self->setParam('display_wire_frames', $display_wire_frames);


    my $display_lang_tags = $preference_service->getPreference('display_lang_tags');
    my $lang_tags_button = $button_service->makeButton({
        lang_key => $display_lang_tags ? 'hide_lang_tags' : 'display_lang_tags',
        action   => '__set_preference__',
        preference_key   => 'display_lang_tags',
        preference_value => $display_lang_tags ? FALSE : TRUE,
    });
    $self->setParam('lang_tags_button', $lang_tags_button->getTextLink());
 
    return TRUE;
}

1;

__END__

=back

=head2 Modules Used

L<Solstice::View|Solstice::View>

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3364 $

=head1 SEE ALSO

L<Solstice::View>,
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
