package Solstice::Button::Transition;

# $Id: Transition.pm 3002 2006-01-24 22:57:29Z jdr99 $

=head1 NAME

Solstice::Button::Transition - The standard button type, used to transition between two states.

=head1 SYNOPSIS

  use Solstice::Button:Transition;

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

Return a string containing html for an input type=submit button.

=cut

sub getButton {
    my $self = shift;

    return $self->SUPER::getButton() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name     = $self->{'_name'} || '';
    my $label    = $self->_generateLabel();
    my $tooltip  = $self->_generateTooltip();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('btn_$name', '$tooltip')");
    }

    unless ($self->{'_url'}) {
        return qq|<input name="$name" id="btn_$name" type="submit" name="$name" value="$label" tabindex="$tabindex" onclick="Solstice.Button.set('$name')"/>$script|;
    }

    my $handler = $self->_generateHandler();
    return qq|<input name="$name" id="btn_$name" type="button" name="$name" value="$label" tabindex="$tabindex" onclick="$handler"/>$script|;
}

=item getNoSubmitButton()

Return a string containing html for an input type=button; that is, a
button that cannot submit a form.

=cut

sub getNoSubmitButton {
    my $self = shift;

    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name     = $self->{'_name'} || '';
    my $label    = $self->_generateLabel();
    my $tooltip  = $self->_generateTooltip();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();
    my $handler  = $self->_generateHandler();
    
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('btn_$name', '$tooltip')");
    }
    return qq|<input name="$name" id="btn_$name" type="button" name="$name" value="$label" tabindex="$tabindex" onclick="$handler"/>$script|;
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
    my $handler  = $self->_generateHandler();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }

    return qq|<a href="javascript:void($handler);" name="$name" id="link_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
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
    my $handler  = $self->_generateHandler();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
    }

    return qq|<a href="javascript:void($handler);" name="$name" id="img_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a>$script|;
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
    my $handler  = $self->_generateHandler();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
        $self->getOnloadService()->addEvent("Solstice.addToolTip('txt_$name', '$tooltip')");
    }

    return qq|<a href="javascript:void($handler);" name="$name" id="img_$name" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a> <a href="javascript:void($handler);" id="txt_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=item getPseudoButton()

=cut

sub getPseudoButton {
    my $self = shift;

    return $self->SUPER::getPseudoButton() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name     = $self->{'_name'}  || '';
    my $label    = $self->_generateLabel(); 
    my $title    = $self->_generateTitle();
    my $tooltip  = $self->_generateTooltip();
    my $image    = $self->{'_image'} ? ('<img src="'.$self->{'_image'}.'" alt=""/> ') : '';
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();
    my $handler  = $self->_generateHandler();
    my $keypress_handler = $self->_generateKeyPressHandler();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('pseudo_$name', '$tooltip')");
    }

    return qq|<div name="$name" id="pseudo_$name" title="$title" onmouseover="this.style.cursor='pointer';" onmouseout="this.style.cursor='default';" onclick="void($handler);" onkeydown="void($keypress_handler);" tabindex="$tabindex" >$image$label</div>$script|;
}

=item getDropDown()

=cut

sub getDropDown {
    my $self = shift;

    return $self->SUPER::getDropDown() if $self->{'_disabled'};
    unless ($self->{'_has_javascript'}) {
        $self->{'_label'} = 'Go';
        return $self->getNoscriptButton();
    }
    
    my $name     = $self->{'_name'}  || '';
    my $label    = $self->_generateLabel();
    my $title    = $self->_generateTitle();
    my $tooltip  = $self->_generateTooltip();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();
    my $handler  = $self->_generateHandler();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('dropdown_$name', '$tooltip')");
    }

    my $options = '';
    for my $option ( @{$self->{'_options'}} ) {
        $options .= '<option value="'.$option->{'value'}.'"'.
            ($option->{'selected'} ? ' selected="selected"' : '').'>'.
            $option->{'label'}.'</option>';
    }

    return qq|<select id="dropdown_$name" name="$label" title="$title" tabindex="$tabindex" onchange="$handler">$options</select>$script|;
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
            name => 'ScriptName',
            key  => '_script_name',
            type => 'String',
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
