package Solstice::View::Breadcrumbs;

use strict;
use warnings;
use 5.006_000;

use Solstice::StringLibrary qw(unrender truncstr);

use constant TRUE  => 1;
use constant FALSE => 0;
use constant DEFAULT_BUTTON_LABEL_WIDTH => 50;

use base qw(Solstice::View);

our ($VERSION) = ('$Revision: $' =~ /^\$Revision:\s*([\d.]*)/);

our $template = 'breadcrumbs.html';

sub new {
    my $obj = shift;
    my $self = $obj->SUPER::new(@_);
    
    $self->_setTemplatePath('templates/');
    return $self;
}

sub addButton {
    my $self = shift;
    my $button = shift;

    push @{$self->{'_buttons'}}, $button;
    return;
}

sub _getButtons {
    my $self = shift;
    return $self->{'_buttons'};
}

sub setTitleButton {
    my $self = shift;
    $self->{'_title_button'} = shift;
}

sub getTitleButton {
    my $self = shift;
    return $self->{'_title_button'};
}

sub setDescription {
    my $self = shift;
    $self->{'_description'} = shift;
}

sub getDescription {
    my $self = shift;
    return $self->{'_description'};
}

sub setTruncateWidth {
    my $self = shift;
    $self->{'_truncate_button_width'} = shift;
}   

sub getTruncateWidth {
    my $self = shift;
    return $self->{'_truncate_button_width'} || DEFAULT_BUTTON_LABEL_WIDTH;
}

sub generateParams {
    my $self = shift;

    my $buttons = $self->_getButtons() || [];

    for my $button (@$buttons) {
        $button->setLabel(truncstr($button->getLabel(),$self->getTruncateWidth()));
        $self->addParam('buttons', {
            button => $button->getTextLink(),
        });
    }

    my $title_button = $self->getTitleButton();
    $self->setParam('has_title_button', (defined $title_button));
    $self->setParam('title_button', $title_button->getTextLink())if defined $title_button;
    $self->setParam('description', $self->getDescription());

    return TRUE;
}

1;
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


