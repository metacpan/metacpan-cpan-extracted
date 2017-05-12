package Solstice::Button::Static;

# $Id: Static.pm 2933 2006-01-03 18:53:04Z jlaney $

=head1 NAME

Solstice::Button::Static - A button pointing to a static, non-Solstice url. 

=head1 SYNOPSIS

# Partial implementation of the Solstice::Button API.  Adds a getURL() method, which returns the static url.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Button Solstice::Service::Memory);

use Solstice::ConfigService;
use Solstice::StringLibrary qw(strtourl);

use constant DEFAULT_TARGET => '_self';

our %targets = (
    self    => '_self',
    new     => '_blank',
    blank   => '_blank',
    top     => '_top',
    parent  => '_parent',
);

our ($VERSION) = ('$Revision: 3002 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::Button|Solstice::Button>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut

=item getURL()

Returns the static url for this 'button'.

=cut

sub getURL {
    my $self = shift;

    return $self->{'_url'};
}

=item getImageLink()

Return HTML for an image link.

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
    my $url      = $self->getURL();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
    }

    return qq|<a href="$url" onclick="javascript:void($handler); return false;" name="$name" id="img_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a>$script|;
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
    my $url      = $self->getURL();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }

    return qq|<a href="$url" onclick="javascript:void($handler); return false;" name="$name" id="link_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}


=item getButton()

Returns HTML for a button link.

=cut

sub getButton {
    my $self = shift;

    return $self->SUPER::getButton() if $self->{'_disabled'};

    my $name    = $self->{'_name'}  || '';
    my $target  = $self->_generateTarget();
    my $tooltip = $self->_generateTooltip();
    my $title   = $self->_generateTitle(); 
    my $label   = $self->_generateLabel(); 
    my $url     = $self->getURL();
    my $client_action = $self->{'_client_action'} || '';

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('btn_$name', '$tooltip')");
    }

    #this <a> hack is here so I can rely on the browser to sort out the abs/rel/docbase href issues
    if ($client_action) {
        return qq|<a id="btn_a_$name" href="$url"></a><input type="button" id="btn_$name" value="$label" onclick="if ($client_action) window.location = document.getElementById('btn_a_$name').href;">|;
    } else {
        return qq|<a id="btn_a_$name" href="$url"></a><input type="button" id="btn_$name" value="$label" onclick="window.location.href = document.getElementById('btn_a_$name').href;">|;
    }
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
    my $url      = $self->getURL();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
        $self->getOnloadService()->addEvent("Solstice.addToolTip('txt_$name', '$tooltip')");
    }

    return qq|<a href="$url" onclick="javascript:void($handler); return false;" name="$name" id="img_$name" title="$title" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;"><img src="$image" alt=""/></a> <a href="$url" onclick="javascript:void($handler); return false;" id="txt_$name" title="$title" tabindex="$tabindex" onmouseover="window.status='$jstitle'; return true;" onmouseout="window.status=''; return true;">$label</a>$script|;
}

=item getPseudoButton()

=cut

sub getPseudoButton {
    my $self = shift;

    return $self->SUPER::getPseudoButton() if $self->{'_disabled'};

    my $name    = $self->{'_name'}  || '';
    my $title   = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();
    my $label   = $self->_generateLabel();
    my $image    = $self->{'_image'} ? ('<img src="'.$self->{'_image'}.'" alt=""/> ') : '';
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $url     = $self->getURL();
    my $client_action = $self->{'_client_action'} || '';

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('pseudo_$name', '$tooltip')");
    }

    if ($client_action) {
        return qq|<div id="pseudo_$name" title="$title" onmouseover="this.style.cursor='pointer';" onmouseout="this.style.cursor='default';" onclick="if ($client_action) window.location.href = '$url';" tabindex="$tabindex">$image$label</div>|;
    } else {
        return qq|<div id="pseudo_$name" title="$title" onmouseover="this.style.cursor='pointer';" onmouseout="this.style.cursor='default';" onclick="window.location='$url';" tabindex="$tabindex">$image$label</div>|;
    }
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
    my $title    = $self->_generateTitle();
    my $tooltip  = $self->_generateTooltip();
    my $url      = $self->getURL();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $script   = $self->_generateInlineScript();
  
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('dropdown_$name', '$tooltip')");
    }
 
    my $options = '';
    for my $option ( @{$self->{'_options'}} ) {
        $options .= '<option value="'.($option->{'url'} || $url).'"'.
            ($option->{'selected'} ? ' selected="selected"' : '').'>'.
            $option->{'label'}.'</option>';
    }

    return qq|<select id="dropdown_$name" name="dropdown_$name" title="$title" tabindex="$tabindex" onchange="Solstice.Button.alternateSubmit(this.options[this.selectedIndex].value, '$name')">$options</select>$script|;
}

=back

=head2 Private Methods

=over 4

=cut

=item _generateTarget()

=cut

sub _generateTarget {
    my $self = shift;
    return DEFAULT_TARGET unless $self->{'_target'};
    
    return $targets{$self->{'_target'}} || DEFAULT_TARGET; 
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Target',
            key  => '_target',
            type => 'String',
        },
        {
            name    => 'URL',
            key     => '_url',
            type    => 'String',
            private_get => 1,
        },
    ];
}

1;
__END__

=back

=head2 Modules Used

L<Solstice::Model|Solstice::Model>,
L<StringLibrary|StringLibrary>.

=head1 AUTHOR

Catalyst Group, E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 2933 $ 



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
