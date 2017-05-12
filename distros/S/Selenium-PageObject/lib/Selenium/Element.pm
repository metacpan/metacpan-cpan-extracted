# ABSTRACT: Unified way of interacting with Selenium & WebDriver elements, with a focus on inputs.
# PODNAME: Selenium::Element

package Selenium::Element;
$Selenium::Element::VERSION = '0.012';
use 5.010;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed reftype looks_like_number);
use Data::Random;


sub new {
    my ($class,$element,$driver,$selector) = @_;
    confess("Constructor must be called statically, not by an instance") if ref($class);
    return undef if !$element;
    confess("Element driver invalid: must be WWW::Selenium object or false (element is a Selenium::Remote::Webelement)") unless $driver == 0 || (blessed($driver) && blessed($driver) eq 'WWW::Selenium' );

    my $self = {
        'driver' => $driver,
        'element' => $element,
        'selector' => $selector
    };

    bless $self, $class;
    return $self;
}


sub get_tag_name {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    if ($self->{'driver'}) {
        my @parts = split(qr/=/,$self-{'element'});
        #TODO If you can't do it with both of these, you have no business doing it...but this could be expanded to everything eventually...
        confess('WWW::Selenium drivers can only get tag name if selector is of type "id" or "css"') unless scalar(grep {$_ eq $parts[0]} qw(id css));
        my $js = $parts[0] eq 'id' ? 'document.getElementById("'.$parts[1].'").nodeName' : 'document.querySelectorAll("'.$parts[1].'")[0].nodeName';
        return lc($self->javascript($js));
    }
    return $self->{'element'}->get_tag_name();
}


sub get_type {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    return undef unless $self->is_input;
    return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'}.'@type') : $self->{'element'}->get_attribute('type');
}

#Input specific stuf
#TODO cache the results of all this stuff?


sub is_input {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_tag_name() eq 'input';
}


sub is_textinput {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    my $itype = $self->get_type();
    my $ret = scalar(grep {$_ eq $itype} ('password', 'text'));
    return $ret || $self->get_tag_name() eq 'textarea';
}


sub is_select {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_tag_name() eq 'select';
}


sub is_multiselect {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    return 0 if !$self->is_select;
    return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'multiple') : $self->{'element'}->get_attribute('multiple');
}


sub is_radio {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_type() eq 'radio';
}


sub is_checkbox {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_type() eq 'checkbox';
}


sub is_submit {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_type() eq 'submit';
}


sub is_fileinput {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_type() eq 'file';
}


sub is_form {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("WWW::Selenium does not support getting tag type of elements") if $self->{'driver'};
    return $self->get_tag_name() eq 'form';
}


sub is_option {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("WWW::Selenium does not support getting tag type of elements") if $self->{'driver'};
    return $self->get_tag_name() eq 'option';
}


sub is_hiddeninput {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->get_type() eq 'hidden';
}


sub is_enabled {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    #Note that this will be more or less a no-op for WWW::Selenium, as there's no real way to get the tag name, so we will never see this branch
    return $self->{'driver'} ? $self->{'driver'}->is_editable($self->{'element'}) : $self->{'element'}->is_enabled();
}


sub get_options {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    return () unless $self->is_select();
    if ($self->{'driver'}) {
        #XXX obviously not reliable
        carp("WARNING: WWW::Selenium has reduced ability to get options!  This may not work as you expect.");
        my @labels = $self->{'driver'}->get_select_options($self->{'element'});
        return map {Selenium::Element->new("css=option[value=$_]",$self->{'driver'})} @labels;
    }
    my @opts = $self->{'element'}->{'driver'}->find_child_elements($self->{'element'},'option','tag_name');
    return map {Selenium::Element->new($_,0)} @opts;
}


#Convenience method for selects
sub has_option {
    my ($self,$option) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Option must be passed as argument") unless defined($option);
    return 0 if !$self->is_select();
    return scalar(grep {$_->name eq $option} $self->get_options());
}


sub is_selected {
    my $self = shift;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Element must be option to check if selected") unless $self->is_option;
    return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'selected') : $self->{'element'}->get_attribute('selected');
}


sub get {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);

    #Try to get various stuff based on what it is
    if ($self->is_checkbox || $self->is_radio) {
        return $self->{'driver'} ? $self->{'driver'}->is_checked() : $self->{'element'}->is_selected();
    } elsif ($self->is_select) {
        if ($self->is_multiselect) {
            my @options = grep {defined $_} map {$_->is_selected ? $_->name : undef} $self->get_options;
            return \@options;
        } else {
            return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'value') : $self->{'element'}->get_attribute('value');
        }
    } elsif ( $self->is_hiddeninput || $self->is_fileinput || $self->is_textinput) {
        return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'value') : $self->{'element'}->get_attribute('value');
    } elsif ($self->is_option) {
        return $self->{'driver'} ? defined $self->{'driver'}->get_attribute($self->{'element'},'selected') : defined $self->{'element'}->get_attribute('selected');
    } else {
        $self->{'driver'} ? $self->{'driver'}->get_text($self->{'element'}) : $self->{'element'}->get_text();
    }
}


sub id {
    my $self = shift;
    return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'id') : $self->{'element'}->get_attribute('id');
}


sub name {
    my $self = shift;
    return $self->{'driver'} ? $self->{'driver'}->get_attribute($self->{'element'},'name') : $self->{'element'}->get_attribute('name');
}


sub clear {
    my ($self) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Element must be text") unless $self->is_textinput();
    if ($self->{'driver'}) {
        #TODO If you can't do it with both of these, you have no business doing it...but this could be expanded to everything eventually...
        confess('WWW::Selenium drivers can only clear text if selector is of type "id" or "css"') unless scalar(grep {$_ eq $self->{'selector'}->[1]} qw(id css));
        my $js = $self->{'selector'}->[1] eq 'id' ? 'document.getElementById("'.$self->{'selector'}->[0].'").value = ""' : 'document.querySelectorAll("'.$self->{'selector'}->[0].'")[0].value = ""';
        $self->javascript($js);
    } else {
        $self->{'element'}->clear();
    }
    return 1;
}


sub set {
    my ($self,$value,$callback) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Value must be passed to set") unless defined($value);
    confess("Callback must be subroutine") if defined($callback) && reftype($callback) ne 'CODE';

    my $enabled = $self->is_enabled();
    carp "Attempting to set disabled element" unless $enabled;
    return undef unless $enabled;
    my $ret = 0;

    #Try to set various stuff based on what it is
    SETBLOCK : {
        if ($self->is_checkbox || $self->is_radio) {
            my $selected = $self->{'driver'} ? $self->{'driver'}->is_checked() : $self->{'element'}->is_selected();
            last SETBLOCK if ($selected && $value) || (!$selected && !$value); #Return false if state hasn't changed
            $self->{'driver'} ? $self->{'driver'}->click($self->{'element'}) : $self->{'element'}->click();
            $ret = 1;
        } elsif ($self->is_textinput) {
            $self->clear();
            $self->{'driver'} ? $self->{'driver'}->type_keys($self->{'element'},$value) : $self->{'element'}->send_keys($value);
            $ret = 1;
        } elsif ($self->is_fileinput) {
            if ($self->{'driver'}) {
                $self->{'driver'}->attach_file($self->{'element'},$value);
            } else {
                $self->{'element'}->send_keys($value);
            }
            $ret = 1;
        } elsif ($self->is_hiddeninput) {
            #TODO make this work a bit more universally if possible
            confess("Setting values on hidden elements without IDs not supported") unless $self->id;
            carp("Setting value of hidden element, this may result in unexpected behavior!");
            my $js = 'document.getElementById("'.$self->id.'").value = \''.$value.'\';';
            $self->javascript($js);
            $ret = 1;
        } elsif ($self->is_select) {
            $value = [$value] if reftype($value) ne 'ARRAY';
            if ($self->{'driver'}) {
                foreach my $val (@$value) {
                    $self->{'driver'}->type($self->{'element'},$val);
                }
            } else {
                foreach my $val ($self->get_options()) {
                    if (grep {$val->{'element'}->get_attribute('name') eq $_ } @$value) {
                        #Leave values high if they are requested
                        $val->click if !$val->is_selected;
                    } else {
                        #otherwise ensure low values
                        $val->click if $val->is_selected;
                    }
                }
            }
            $ret = 1;
        } elsif ($self->is_option) {
            my $current = $self->get;
            $self->click if ( (!$current && $value) || ($current && !$value) );
        } else {
            confess("Don't know how to set value to a non-input element!");
        }
    }

    #Can't set anything else!
    return $self->_doCallback($callback) || $ret;
}

sub _doCallback {
    my ($self,$cb) = @_;
    return 0 if !$cb;
    return &$cb($self,$self->{'driver'} ? $self->{'driver'} : $self->{'element'}->{'driver'});
}


sub randomize {

}


sub javascript {
    my ($self, $js) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    return $self->{'driver'} ? $self->{'element'}->get_eval($js) : $self->{'element'}->{'driver'}->execute_script($js);
}


sub click {
    my ($self,$callback) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Callback must be subroutine") if defined($callback) && reftype($callback) ne 'CODE';
    $self->{'driver'} ? $self->{'driver'}->click($self->{'element'}) : $self->{'element'}->click();

    return $self->_doCallback($callback) || 1;
}


sub submit {
    my ($self,$callback) = @_;
    confess("Object parameters must be called by an instance") unless ref($self);
    confess("Callback must be subroutine") if defined($callback) && reftype($callback) ne 'CODE';
    return 0 if !$self->is_form();
    $self->{'driver'} ? $self->{'driver'}->submit($self->{'element'}) : $self->{'element'}->submit();

    return $self->_doCallback($callback) || 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Element - Unified way of interacting with Selenium & WebDriver elements, with a focus on inputs.

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    package ExamplePageObject;
    use base qw{Selenium::PageObject};
    sub do_something_returning_an_element {
        my $self = shift;
        return $self->getElement('radElement','id');
    }
    1;

    use Selenium::Remote::Driver;

    my $driver = Selenium::Remote::Driver->new({'remote_server_addr' => '127.0.0.1'});
    my $pobj = ExamplePageObject->new($driver);
    my $element = $pobj->do_something_returning_an_element();
    my $status = $element->get();
    $element->set('supercool') if $status ne 'supercool';

=head1 DESCRIPTION

Smooths out the interface between WWW::Selenium and Selenium::Remote::Driver elements.
Also creates a unified set/get interface for all inputs.

=head1 CONSTRUCTOR

=head2 new(ELEMENT,DRIVER,SELECTOR)

Create a new Selenium::Element.  You should never have to use/override this except in the most extreme of circumstances.
Use getElement/getElements instead.

B<INPUTS>:

I<ELEMENT (MIXED)> - Either the WWW::Selenium locator string or a Selenium::Remote::WebElement, depending on your driver

I<DRIVER (MIXED)> - Either a WWW::Selenium element or false, depending on your driver (the WebElement has the driver in the latter case)

I<SELECTOR (ARRAYREF[string])> - Arrayref of the form [selector,selectortype]

B<OUTPUT>:

  new Selenium::Element

=head1 GETTERS

=head2 get_tag_name

Returns the tag name of the Element object.

=head2 get_type

Returns the type of the Element object if it is an input tag.

=head2 is_input

Returns whether the element is an input.

=head2 is_textinput

Returns whether the element is an input with type 'text' or 'password' or a textarea.

=head2 is_select

Returns whether the element is a select.

=head2 is_multiselect

Returns whether the element is a select with the 'multiple' attribute.

=head2 is_radio

Returns whether the element is a radio button.

=head2 is_checkbox

Returns whether the element is a check box.

=head2 is_submit

Returns whether the element is an input of the type 'submit'.

=head2 is_fileinput

Returns whether the element is an input of the type 'file'.

=head2 is_form

Returns whether the element is a form.

=head2 is_option

Returns whether the element is an option.

=head2 is_hiddeninput

Returns whether the element is an input of type 'hidden'.

=head2 is_enabled

Returns whether the element is a disabled input.

=head2 get_options

Returns a list containing Selenium::Element objects that are child options, if this object is a select.

=head2 has_option(option)

Returns whether this element has a child option with the provided name, provided this object is a select.

B<INPUT>:
I<OPTION (STRING)> - the name of the desired option

B<OUTPUT>:
I<BOOLEAN> - whether this object has said option as a child

=head2 is_selected

Returns whether the element is selected.

=head2 get

Returns the current value of the element.

B<OUTPUT>:

I<MIXED> - Depends on the type of element.
    Boolean for check boxes, options and radio buttons
    Arrayrefs of option names for multi-selects
    Strings for single selects, text/hidden inputs and non-inputs like paragraphs, table cells, etc.

=head2 id

Returns the element's id.

=head2 name

Returns the element's name.

=head1 SETTERS

=head2 clear

Clear a text input.

=head2 set(value,[callback])

Set the value of the input to the provided value, and execute the provided callback if provided.
The callback will be provided with the caller and the selenium driver as arguments.

B<INPUT>:

I<VALUE (MIXED)> - STRING, BOOLEAN or ARRAYREF, depending on the type of element you are attempting to set.
    Strings are for text inputs, hidden inputs or non-multi selects, Booleans for radio buttons, check boxes and options, and Arrayrefs of strings for multi-selects.
    Selects take the name of the option as arguments.

I<CALLBACK (CODE) [optional]> - some anonymous function

B<OUTPUT>:

I<MIXED> - whether the set succeeded, or whatever your callback feels like returning, supposing you provided one.

=head2 randomize(options)

Randomizes the input, depending on the type of element.  Useful for fuzzing.

B<INPUT>:

I<HASH>: Options appropriate to the relevant Data::Random method.

B<OUTPUT>:

I<MIXED> - Random value that has been set into the field, or false on failure.

=head1 STATE CHANGE METHODS

=head2 javascript(js)

Execute an arbitrary Javascript string and return the output.
Handy in callbacks that wait for JS events.

B<INPUT>:

I<JS (STRING)> - any valid javascript string

B<OUTPUT>:

I<MIXED> - depends on your javascript's output.

=head2 click

Click the element.

=head2 submit([callback])

Submit the element, supposing it's a form

B<INPUT>:

I<CALLBACK (CODE) [optional]> - anonymous function

B<OUTPUT>:

I<MIXED> - Whether the action succeeded or whatever your callback returns, supposing it was provided.

=head1 SEE ALSO

L<WWW::Selenium>

L<Selenium::Remote::Driver>

=head1 SPECIAL THANKS

cPanel, Inc. graciously funded the initial work on this Module.

=head1 AUTHOR

George S. Baugh <teodesian@cpan.org>

=head1 SOURCE

The development version is on github at L<http://github.com/teodesian/Selenium-PageObjects-Perl>
and may be cloned from L<git://github.com/teodesian/Selenium-PageObjects-Perl.git>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by George S. Baugh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
