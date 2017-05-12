package Solstice::Button::PopIn;

# $Id: PopIn.pm 3002 2006-01-24 22:57:29Z jdr99 $

=head1 NAME

Solstice::Button::PopIn - Create a DHTML-based popup.

=head1 SYNOPSIS

  use Solstice::Button:PopIn;

  See L<Solstice::Button|Solstice::Button> for usage.

=head1 DESCRIPTION

ee L<Solstice::Button|Solstice::Button> for description.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Button);

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

    my $name     = $self->{'_name'} || '';
    my $label    = $self->_generateLabel(); 
    my $title    = $self->_generateTitle(); 
    my $tooltip  = $self->_generateTooltip(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $modal = $self->{'_is_modal'} || 0;
    my $draggable = defined $self->{'_is_draggable'} ? $self->{'_is_draggable'} : 1;
    my $width = $self->{'_width'} || '';

    my $script   = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('$name', '$tooltip')");
    }

    return qq|<input name="$name" type="button" id="$name" value="$label" tabindex="$tabindex" onclick="Solstice.YahooUI.raisePopIn('$name',$modal, $draggable, '$width');"/>$script|;
}

=item getTextLink()

Returns HTML for a text link.

=cut

sub getTextLink {
    my $self = shift;

    return $self->SUPER::getTextLink() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name     = $self->{'_name'} || '';
    my $label    = $self->_generateLabel(); 
    my $tooltip  = $self->_generateTooltip(); 
    my $title    = $self->_generateTitle(); 
    my $jstitle  = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();
    my $modal = $self->{'_is_modal'} || 0;
    my $draggable = defined $self->{'_is_draggable'} ? $self->{'_is_draggable'} : 1;
    my $width = $self->{'_width'} || '';

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('$name', '$tooltip')");
    }

    return qq|<a href="javascript:void(0);" name="$name" id="$name" tabindex="$tabindex" title="$title" onclick="Solstice.YahooUI.raisePopIn('$name',$modal, $draggable, '$width');" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=item getImageLink()

Returns HTML for an image link.

=cut

sub getImageLink {
    my $self = shift;

    return $self->SUPER::getImageLink() if $self->{'_disabled'};
    return $self->getNoscriptImage() unless $self->{'_has_javascript'};
    
    my $name     = $self->{'_name'}  || '';
    my $tooltip  = $self->_generateTooltip(); 
    my $title    = $self->_generateTitle(); 
    my $jstitle  = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $image    = $self->{'_image'} || '';
    my $alt      = $self->{'_title'}  || '';
    my $script   = $self->_generateInlineScript();  
    my $modal = $self->{'_is_modal'} || 0;
    my $draggable = defined $self->{'_is_draggable'} ? $self->{'_is_draggable'} : 1;
    my $width = $self->{'_width'} || '';

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('$name', '$tooltip')");
    }
    return qq|<a href="javascript:void(0);" name="$name" id="$name" tabindex="$tabindex" title="$title" onclick="Solstice.YahooUI.raisePopIn('$name',$modal, $draggable, '$width');" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a>$script|;
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
    
    my $name     = $self->{'_name'}  || '';
    my $label    = $self->_generateLabel(); 
    my $tooltip  = $self->_generateTooltip();
    my $title    = $self->_generateTitle(); 
    my $jstitle  = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $image    = $self->{'_image'} || '';
    my $script   = $self->_generateInlineScript();
    my $modal = $self->{'_is_modal'} || 0;
    my $draggable = defined $self->{'_is_draggable'} ? $self->{'_is_draggable'} : 1;
    my $width = $self->{'_width'} || '';
    
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('text_link_$name', '$tooltip')");
        $self->getOnloadService()->addEvent("Solstice.addToolTip('$name', '$tooltip')");
    }
    return qq|<a href="javascript:void(0);" name="$name" id="text_link_$name" title="$title" onclick="Solstice.YahooUI.raisePopIn('$name',$modal, $draggable, '$width');" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a> <a href="javascript:void(0);" id="$name" tabindex="$tabindex" title="$title" onclick="Solstice.YahooUI.raisePopIn('$name',$modal, $draggable, '$width');" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=back

=head2 Private Methods

=over 4

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'IsDraggable',
            key  => '_is_draggable',
            type => 'Integer',
        },
        {
            name    => 'Width',
            key     => '_width',
            type    => 'String',
        },
        {
            name => 'IsModal',
            key  => '_is_modal',
            type => 'Integer',
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
