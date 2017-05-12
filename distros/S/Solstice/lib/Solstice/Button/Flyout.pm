package Solstice::Button::Flyout;

# $Id: Flyout.pm 3364 2006-05-05 07:18:21Z mcrawfor $

=head1 NAME

Solstice::Button::Flyout - Models flyout buttons with nested actions.

=head1 SYNOPSIS

  use Solstice::Button:Flyout;

  See L<Solstice::Button|Solstice::Button> for usage.

=head1 DESCRIPTION

ee L<Solstice::Button|Solstice::Button> for description.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Button);

use Solstice::StringLibrary qw(strtojavascript);

our ($VERSION) = ('$Revision: 3364 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Button|Solstice::Button>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item setFlyouts(\@buttons)

Set a reference to a list of button objects comprising the flyout menu.

=item getFlyouts()

Returns a reference to a list of flyout button objects.

=item setStyleClass($string)

Set a style class for the menu. 

=item getStyleClass()

Return a style class for the menu.

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
    
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }

    return qq|<a id="link_$name" href="javascript:void(0);" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;" onclick="Solstice.Flyout.menuReg.openMenu('$name', event);" oncontextmenu="Solstice.Flyout.menuReg.openMenu('$name', event); return false;">$label</a>$script|;
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

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
    }

    return qq|<a id="img_$name" href="javascript:void(0);" tabindex="$tabindex" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;" onclick="Solstice.Flyout.menuReg.openMenu('$name', event);" oncontextmenu="Solstice.Flyout.menuReg.openMenu('$name', event); return false;"><img src="$image" alt=""/></a>$script|;
}

=item getImageTextLink()

Return HTML for a combination image/text link.

=cut

sub getImageTextLink {
    my $self = shift;
    
    return $self->SUPER::getImageTextLink() if $self->{'_disabled'};
    unless ($self->{'_has_javascript'}) {
        return ($self->getNoscriptImage() . ' ' . $self->getNoscriptButton());
    }

    my $name     = $self->{'_name'}  || '';
    my $label    = $self->_generateLabel(); 
    my $tooltip  = $self->_generateTooltip();
    my $title    = $self->_generateTitle(); 
    my $jstitle  = $self->_generateScriptTitle(); 
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $image    = $self->{'_image'} || '';
    my $script   = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_text_$name', '$tooltip')");
    }
    
    return qq|<a id="img_text_$name" href="javascript:void(0);" tabindex="$tabindex" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;" onclick="Solstice.Flyout.menuReg.openMenu('$name', event);" oncontextmenu="Solstice.Flyout.menuReg.openMenu('$name', event); return false;"><img src="$image" alt=""/></a> <a href="javascript:void(0);" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;" onclick="Solstice.Flyout.menuReg.openMenu('$name', event);" oncontextmenu="Solstice.Flyout.menuReg.openMenu('$name', event); return false;" title="$title">$label</a>$script|;
}

sub addFlyoutButton {
    my $self = shift;
    my $button= shift;
    
    $self->{'_flyouts'} = [] unless defined $self->{'_flyouts'};
    push @{$self->{'_flyouts'}}, $button;
    
    return $button;
}

sub getPseudoButton {
    my $self = shift;

    return $self->SUPER::getPseudoButton() if $self->{'_disabled'};
    return $self->getNoscriptButton() unless $self->{'_has_javascript'};

    my $name     = $self->{'_name'} || '';
    my $label    = $self->_generateLabel();  
    my $tooltip  = $self->_generateTooltip();
    my $title    = $self->_generateTitle();
    my $jstitle  = $self->_generateScriptTitle();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_text_$name', '$tooltip')");
    }

    return qq|<div id="pseudo_$name"  title="$title" tabindex="$tabindex" onmouseover="this.style.cursor='pointer'; return true;" onmouseout="window.status=''; return true;" onclick="Solstice.Flyout.menuReg.openMenu('$name', event);" oncontextmenu="Solstice.Flyout.menuReg.openMenu('$name', event); return false;">$label</div>$script|;
}

=back

=head2 Private Methods

=over 4

=cut

=item _generateInlineScript()

=cut

sub _generateInlineScript {
    my $self = shift;

    my $flyout_attributes = join ',', map {
        'new Array(\''.($_->{'_name'} || '').'\', \''.
        $_->_generateScriptLabel().'\', \''.
        $_->_generateScriptTitle().'\', \''.
        ($_->{'_url'} || '').'\', '.
        (defined $_->{'_action'} ? 'false' : 'true').', '.
        (defined $_->{'_disabled'} && $_->{'_disabled'} == 1 ? 'true' : 'false').', '.
        (defined $_->{'_checked'} && $_->{'_checked'} == 1 ? 'true' : 'false').', \''.
        strtojavascript($_->{'_client_action'} || '').'\')' } @{$self->{'_flyouts'}};

    my $script = '<script type="text/javascript">';
    $script .= $self->{'_classname'} ? 'var menu = ' : '';
    $script .= 'Solstice.Flyout.menuReg.createMenu("'.($self->{'_name'} || '').'", new Array('.$flyout_attributes.'));'; 
    $script .= (' menu.setStyleClass("'.$self->{'_classname'}.'")') if $self->{'_classname'};
    $script .= '</script>';
    
    return $script;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Flyouts',
            key  => '_flyouts',
            type => 'ArrayRef',
        },
        {
            name => 'StyleClass',
            key  => '_classname',
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
