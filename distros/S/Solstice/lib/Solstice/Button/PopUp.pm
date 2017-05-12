package Solstice::Button::PopUp;

# $Id: PopUp.pm 3002 2006-01-24 22:57:29Z jdr99 $

=head1 NAME

Solstice::Button::PopUp - Open a new browser window and launch an initial state in it.

=head1 SYNOPSIS

  use Solstice::Button:PopUp;

  See L<Solstice::Button|Solstice::Button> for usage.

=head1 DESCRIPTION

ee L<Solstice::Button|Solstice::Button> for description.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Button);

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_WINDOW_NAME   => 'solsticePopupWindow';
use constant DEFAULT_WINDOW_WIDTH  => 680;
use constant DEFAULT_WINDOW_HEIGHT => 700;
use constant MAX_WINDOW_SIZE       => 800;

our ($VERSION) = ('$Revision: 3002 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Button|Solstice::Button>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item getButton()

=cut

sub getButton {
    my $self = shift;

    return $self->SUPER::getButton() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name       = $self->{'_name'} || '';
    my $label      = $self->_generateLabel(); 
    my $title      = $self->_generateTitle(); 
    my $tooltip    = $self->_generateTooltip();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $url        = $self->{'_popup_url'} || '';
    my $attributes = $self->getPopupAttributes() || ''; 
    my $window     = $self->{'_popup_name'} || DEFAULT_WINDOW_NAME;
    my $script     = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('btn_$name', '$tooltip')");
    }

    return qq|<input id="btn_$name" type="button" name="$name" value="$label" tabindex="$tabindex" onclick="Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window');"/>$script|;
}

=item getTextLink()

Returns HTML for a text link.

=cut

sub getTextLink {
    my $self = shift;

    return $self->SUPER::getTextLink() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};
    
    my $name       = $self->{'_name'} || '';
    my $label      = $self->_generateLabel(); 
    my $tooltip    = $self->_generateTooltip();
    my $title      = $self->_generateTitle(); 
    my $jstitle    = $self->_generateScriptTitle();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $url        = $self->{'_popup_url'} || '';
    my $attributes = $self->getPopupAttributes() || '';
    my $window     = $self->{'_popup_name'} || DEFAULT_WINDOW_NAME;
    my $script     = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }

    return qq|<a id="link_$name" href="javascript:void(Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window'));" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=item getImageLink()

Returns HTML for an image link.

=cut

sub getImageLink {
    my $self = shift;

    return $self->SUPER::getImageLink() if $self->{'_disabled'};
    return $self->getNoscriptImage() unless $self->{'_has_javascript'};
    
    my $name       = $self->{'_name'}  || '';
    my $tooltip    = $self->_generateTooltip();
    my $title      = $self->_generateTitle(); 
    my $jstitle    = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $image      = $self->{'_image'} || '';
    my $alt        = $self->{'_title'}  || '';
    my $url        = $self->{'_popup_url'} || '';
    my $attributes = $self->getPopupAttributes() || '';
    my $window     = $self->{'_popup_name'} || DEFAULT_WINDOW_NAME;
    my $script     = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
    }

    return qq|<a id="img_$name" href="javascript:void(Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window'));" tabindex="$tabindex" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a>$script|;
}

=item getImageTextLink()

Return HTML for a combination image/text link.

=cut

sub getImageTextLink {
    my $self = shift;
    
    return $self->SUPER::getImageTextLink() if $self->{'_disabled'};
    unless ($self->{'_has_javascript'}) {
        return ($self->getNoscriptImage().' '.$self->getNoscriptButton());
    }
    
    my $name       = $self->{'_name'}  || '';
    my $label      = $self->_generateLabel();
    my $tooltip    = $self->_generateTooltip();
    my $title      = $self->_generateTitle(); 
    my $jstitle    = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $image      = $self->{'_image'} || '';
    my $url        = $self->{'_popup_url'} || '';
    my $attributes = $self->getPopupAttributes() || '';
    my $window     = $self->{'_popup_name'} || DEFAULT_WINDOW_NAME;
    my $script     = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }
    return qq|<a id="img_$name" href="javascript:void(Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window'));" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a> <a id="link_$name" href="javascript:void(Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window'));" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=item getPseudoButton()

=cut

sub getPseudoButton {
    my $self = shift;

    return $self->SUPER::getPseudoButton() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};
    
    my $name       = $self->{'_name'}  || '';
    my $label      = $self->_generateLabel(); 
    my $title      = $self->_generateTitle();
    my $tooltip    = $self->_generateTooltip();
    my $image      = $self->{'_image'} ? ('<img src="'.$self->{'_image'}.'" alt=""/> ') : '';
    my $url        = $self->{'_popup_url'} || '';
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $attributes = $self->getPopupAttributes() || '';
    my $window     = $self->{'_popup_name'} || DEFAULT_WINDOW_NAME; 
    my $script     = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('pseudo_$name', '$tooltip')");
    }

    return qq|<div id="pseudo_$name" title="$title" onmouseover="this.style.cursor='pointer';" onmouseout="this.style.cursor='default';" onclick="void(Solstice.Button.newWindowSubmit('$name', '$url', '$attributes', '$window'));" tabindex="$tabindex" >$image$label</div>$script|;
}

=item getPopupAttributes()

=cut

sub getPopupAttributes {
    my $self = shift;

    if (my $file = $self->getPopupFile()) {
        my $width  = $file->getAttribute('width');
        my $height = $file->getAttribute('height');

        if ($width and $height) {
            $width += 20;
            $height += 20;
            if ($height > MAX_WINDOW_SIZE || $width > MAX_WINDOW_SIZE) {
                if ($height > MAX_WINDOW_SIZE) {
                    $width = int($width / $height * MAX_WINDOW_SIZE) || 1;
                    $height = MAX_WINDOW_SIZE;
                } else {
                    $width = MAX_WINDOW_SIZE;
                    $height = int($height / $width * MAX_WINDOW_SIZE) || 1;
                }
            }
        } else {
            $width  = DEFAULT_WINDOW_WIDTH;
            $height = DEFAULT_WINDOW_HEIGHT;
        } 
        
        return ('height='.$height.',width='.$width.',resizable=yes,scrollbars=yes,status=no,toolbar=no,menubar=no');
    }
    return $self->_getPopupAttributes();
}

=back

=head2 Private Methods

=over 4

=cut

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'PopupURL',
            key  => '_popup_url',
            type => 'String',
        },
        {
            name => 'PopupName',
            key  => '_popup_name',
            type => 'String',
        },
        {
            name => 'PopupAttributes',
            key  => '_popup_attributes',
            type => 'String',
            private_get => TRUE,
        },
        {
            name => 'PopupFile',
            key  => '_popup_file',
            #TODO: Accept all Solstice::Resource::File subclasses
            type => 'Solstice::Resource::File::BlackBox',
        },
    ];
}


1;
__END__

=back

=head2 Modules Used

L<Solstice::Button|Solstice::Button>,
L<StringLibrary|StringLibrary>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 3002 $ 



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
