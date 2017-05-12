package Solstice::Button;

# $Id: Button.pm 3370 2006-05-05 22:25:03Z pmichaud $

=head1 NAME

Solstice::Button - A model to hold the data for a Solstice button.

=head1 SYNOPSIS

  use Solstice::ButtonService;
  use Solstice::Button;

  my $button = $button_service->makeButton(...);

  #The public methods in Button are for converting the Button data into an HTML 
  string...
  my $html = $button->getButton();
  $html = $button->getTextLink();
  $html = $button->getImageLink();
  $html = $button->getImageTextLink();
  $html = $button->getDropDown();
  $html = $button->getPseudoButton();
  
=head1 DESCRIPTION

The Button object is designed to be a flexible way of allowing a user to engage with the solstice framework, without the programmer needing to make sure that what they do is compatable with state processing.  It was originally designed to make buttons, hence the name, but quickly grew into a tool to manage any sort of user submission to the system.

=cut

use 5.006_000;
use strict;
use warnings;

use base qw(Solstice::Model);

use Solstice::StringLibrary qw(strtojavascript unrender trimstr extracttext);

use constant DEFAULT_LABEL => 'Submit';

our ($VERSION) = ('$Revision: 3370 $' =~ /^\$Revision:\s*([\d.]*)/);

=head2 Superclass

L<Solstice::View|Solstice::View>

=head2 Export

No symbols exported.

=head2 Methods

=over 4

=cut


=item new()

Constructor, sets the default button template.

=cut

sub new {
    my $class = shift;
    my $params = shift;

    my $self = $class->SUPER::new(@_);

    for my $key (keys %$params) {
        $self->{'_'.$key} = $params->{$key};
    }

    return $self;
}

=item getHTML()

Legacy method, use getButton() instead.

=cut

sub getHTML {
    my $self = shift;
    return $self->getButton(@_);
}

=item getButton()

=cut

sub getButton {
    my $self = shift;

    my $name  = $self->{'_name'}  || '';
    my $label = $self->_generateLabel();
    my $title = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('btn_$name', '$tooltip')");
    }

    return qq|<input type="button" id="btn_$name" name="$name" value="$label" disabled="disabled"/>|;
}

=item getTextLink()

=cut

sub getTextLink {
    my $self = shift;

    my $name  = $self->{'_name'}  || '';
    my $label = $self->_generateLabel();
    my $title = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('text_link_$name', '$tooltip')");
    }

    return $self->{'_has_javascript'} 
        ? qq|<span id="text_link_$name"  title="$title">$label</span>|
        : qq|<input id="text_link_$name" type="button" name="$name" value="$label" title="$title" disabled="disabled"/>|;
}

=item getImageLink()

Returns HTML for an image link.

=cut

sub getImageLink {
    my $self = shift;

    my $name  = $self->{'_name'}  || '';
    my $image = $self->{'_image'} || '';
    my $title = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$title')");
    }

    return qq|<img id="img_$name" src="$image" alt="" title="$title"/>|;
}

=item getImageTextLink()

Return HTML for a combination image/text link.

=cut

sub getImageTextLink {
    my $self = shift;

    my $name  = $self->{'_name'}  || '';
    my $image = $self->{'_image'} || '';
    my $label = $self->_generateLabel();
    my $title = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();

    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('img_$name', '$tooltip')");
        $self->getOnloadService()->addEvent("Solstice.addToolTip('link_$name', '$tooltip')");
    }

    return qq|<img id="img_$name" src="$image" alt="" title="$title"/> |.(
        $self->{'_has_javascript'}
            ? qq|<span id="link_$name" title="$title">$label</span>|
            : qq|<input id="link_$name" type="button" name="$name" value="$label" title="$title" disabled="disabled"/>|);
}

=item getPseudoButton()

Returns HTML for a "clickable" block element.

=cut

sub getPseudoButton {
    my $self = shift;
    
    my $name    = $self->{'_name'}  || '';
    my $label   = $self->_generateLabel();
    my $tooltip = $self->_generateTooltip();
    my $title   = $self->_generateTitle();
    my $image   = $self->{'_image'} ? ('<img src="'.$self->{'_image'}.'" alt=""/> ') : '';
    
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('pseudo_$name', '$tooltip')");
    }
    return qq|<div id="pseudo_$name" title="$title">$image$label</div>|;
}

=item getDropDown()

Returns HTML for a dropdown that will submit on select.

=cut

sub getDropDown {
    my $self = shift;

    my $name    = $self->{'_name'}  || '';
    my $label = $self->_generateLabel();
    my $title = $self->_generateTitle();
    my $tooltip = $self->_generateTooltip();
    
    if (defined $tooltip) {
        $self->getOnloadService()->addEvent("Solstice.addToolTip('dropdown_$name', '$tooltip')");
    }

    my $html = qq|<select id="dropdown_$name" name="$label" title="$title" disabled="disabled">|;
    for my $option ( @{$self->{'_options'}} ) {
        $html .= ($option->{'selected'})
            ? '<option value="'.$option->{'value'}.'" selected="selected">'.$option->{'label'}.'</option>'
            : '<option value="'.$option->{'value'}.'">'.$option->{'label'}.'</option>';
    }
    $html .= '</select>';
    return $html;
}

=item getNoscriptButton()

=cut

sub getNoscriptButton {
    my $self = shift;

    my $name     = $self->{'_name'} || '';
    my $title    = $self->_generateTitle();
    my $tabindex = defined $self->{'_tabindex'} ? $self->{'_tabindex'} : 0;
    my $label    = trimstr($self->_generateLabel() || DEFAULT_LABEL);
    $label =~ s/[\s\t]+/ /g; # Collapse internal whitespace 
    
    return qq|<input type="submit" name="$name" value="$label" title="$title" tabindex="$tabindex"/>|;
}

=item getNoscriptImage()

=cut

sub getNoscriptImage {
    my $self = shift;

    my $name  = $self->{'_name'} || '';
    my $image = $self->{'_image'} || '';
    my $title = $self->_generateTitle();
    
    return qq|<input type="image" name="$name" src="$image" title="$title" value=""/>|;
}

=item setIsIllegal()

Used by Session code - if this button is used in an expired session this is called 
in order to render it null and void to any controller code that might run

=cut

sub setIsIllegal {
    my $self = shift;

    $self->setAction('__bad_back_button__');
    $self->setAttributes({});
}

=item addAttribute(key, value)

Takes a key, value and store it into the buttons attribute hash

=cut

sub addAttribute {
    my $self = shift;
    my ($key, $value) = @_;
    $self->setAttributes({}) unless defined $self->getAttributes();
    $self->getAttributes()->{$key} = $value;
}

=item removeAttribute(key)

Deletes the value by the specified key

=cut

sub removeAttribute {
    my ($self, $key) = @_;
    return unless defined $key && defined $self->getAttributes();
    delete $self->getAttributes()->{$key};
}
    
sub addClientAction {
    my $self = shift;
    my $action = shift;
    my $client_actions = $self->getClientAction() || '';
    $self->setClientAction($client_actions.$action);
}

=back

=head2 Private Methods

=over 4

=item _generateLabel()

=cut

sub _generateLabel {
    my $self = shift;

    my $label = ($self->{'_lang_key'}) ?
        $self->getLangService($self->{'_namespace'})->getButtonLabel($self->{'_lang_key'}) :
        ($self->{'_label'} || '');

        unless($self->{'_has_javascript'}){
            $label = extracttext($label);
        }

        return $label;
}

=item _generateTitle()

=cut

sub _generateTitle {
    my $self = shift;
    return '' if $self->{'_tooltip'};
    
    my $title = ($self->{'_lang_key'}) ? 
        $self->getLangService($self->{'_namespace'})->getButtonTitle($self->{'_lang_key'}) : 
        ($self->{'_title'} || '');
    
    # Newlines end up becoming a really funky character in tooltips...
    # so replace them with a space
    $title =~ s/[\n\r]/ /g;
    
    return $title;
#    return unrender($title);
}

=item _generateScriptLabel()

=cut

sub _generateScriptLabel {
    my $self = shift;
    return strtojavascript($self->_generateLabel());
}

=item _generateHandler()

=cut

sub _generateHandler {
    my $self = shift;

    if (defined $self->{'_url'}) {
        return 'Solstice.Button.alternateSubmit(\''.$self->{'_url'}.'\', \''.$self->{'_name'}.'\')';
    }
    else {
        return ('Solstice.Button.submit(\''.$self->{'_name'}.'\')');
    }
}

sub _generateKeyPressHandler {
    my $self = shift;

    if(defined $self->{'_url'}) {
        return 'Solstice.Button.keyPressSubmit(event, \''.$self->{'_name'}.'\', \''.$self->{'_url'}.'\')';
    }else {
        return 'Solstice.Button.keyPressSubmit(event, \''.$self->{'_name'}.'\')';
    }
}
=item _generateScriptTitle()

=cut

sub _generateScriptTitle {
    my $self = shift;
    return strtojavascript($self->_generateTitle());
}

=item _generateTooltip()

=cut

sub _generateTooltip {
    my $self = shift;

    return strtojavascript($self->{'_tooltip'});
}

=item _generateInlineScript()

=cut

sub _generateInlineScript {
    my $self = shift;
    return '' unless $self->{'_client_action'} || $self->{'_is_default'};
    
    my $script = '<script type="text/javascript">';
    if ($self->{'_client_action'}) {
        $script .= 'Solstice.Button.registerClientAction("'.$self->{'_name'}.'", "'.$self->{'_client_action'}.'");';
    }
    if ($self->{'_is_default'}) {
        $script .= 'Solstice.Button.setDefault("'.$self->{'_name'}.'");';
    }
    $script .= '</script>';

    return $script;
}

=item _getAccessorDefinition()

=cut

sub _getAccessorDefinition {
    return [
        {
            name => 'Action',
            key  => '_action',
            type => 'String',
        },
        {
            name => 'Attributes',
            key  => '_attributes',
            type => 'HashRef',
        },
        {
            name => 'ClientAction',
            key  => '_client_action',
            type => 'String',
        },
        {
            name => 'HasJavascript',
            key  => '_has_javascript',
            type => 'Boolean',
        },
        {
            name => 'Image',
            key  => '_image',
            type => 'String',
        },
        {
            name    => 'IsDisabled',
            key     => '_disabled',
            type    => 'Boolean',
        },
        {
            name => 'IsDefault',
            key  => '_is_default',
            type => 'Boolean',
        },
        {
            name => 'Label',
            key  => '_label',
            type => 'String',
        },
        {
            name => 'Name',
            key  => '_name',
            type => 'String',
        },
        {
            name => 'Namespace',
            key  => '_namespace',
            type => 'String',
        },
        {
            name => 'Options',
            key  => '_options',
            type => 'ArrayRef',
        },
        {
            name => 'SubsessionChainID',
            key  => '_chain_id',
            type => 'String',
        },
        {
            name => 'SubsessionID',
            key  => '_subsession_id',
            type => 'String',
        },
        {
            name => 'PreferenceKey',
            key  => '_preference_key',
            type => 'String',
        },
        {
            name => 'PreferenceValue',
            key  => '_preference_value',
            type => 'String',
        },
        {
            name => 'Tabindex',
            key  => '_tabindex',
            type => 'Integer',
        },
        {
            name => 'Title',
            key  => '_title',
            type => 'String',
        },
        {
            name => 'Tooltip',
            key  => '_tooltip',
            type => 'String',
        },
        {
            name => 'URL',
            key  => '_url',
            type => 'String',
        },

        {
            name => 'LangKey',
            key  => '_lang_key',
            type => 'String',
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

$Revision: 3370 $ 



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
