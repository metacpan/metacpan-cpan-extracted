package Serengeti::Backend::Native::Elements::Forms;

use strict;
use warnings;

use Serengeti::Backend::Native::HTMLElementProperties;

my %VALID_PROPERTY = make_property_map(
    qw(name acceptCharset action method target)
);

sub register {
    return (
        form    => \&get_formelement_property,
        option  => \&get_optionelement_property,
        input   => \&get_inputelement_property,
    );
}

sub get_formelement_property {
    my ($element, $property) = @_;

    return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
    
    if ($property eq "elements" || $property eq "length") {
        # Now, find all input, select and textarea inputs
        my @inputs = $element->findnodes(".//input | .//textarea | .//select");
        return scalar @inputs if $property eq "length";
        return Serengeti::Backend::Native::HTMLCollection->new(@inputs);
    }
    
    if ($property eq "enctype") {
        my $enctype = $element->attr("enctype");
        return to_DOMString($enctype) if defined $enctype;
        
        # TODO: Check if we have a file input and 
        # set it to mutlipart/form-data instead.
        
        return "application/x-www-form-urlencoded";
    }
    
    return sub { submit($element, @_) } if $property eq "submit";
    
    if ($property eq "reset") {
        return sub {
            
        };
    }
    
    return;
}

sub submit {
    my ($element, $override) = @_;
    
    my $action = $element->attr("action");
    my $method = uc $element->attr("method");
    
    my $browser = $element->root->owner_document->browser;
    
    # Gather input, textarea and hm.. other form elements
    my %form_data = _gather_form_data($element);
    
    $override = {} unless ref $override eq "HASH";
    for (keys %form_data) {
        $form_data{$_} = $override->{$_} if exists $override->{$_};
    }
    
    my $url = $element->root->owner_document->make_url($action);
    
    if ($method eq "POST") {
        $browser->post($url, \%form_data, {});        
    }
    else {
        # Assume GET
        $browser->get($url, \%form_data, {});        
    }
}

sub _gather_form_data {
    my $element = shift;
    
    my %form_data;
    my @inputs = $element->findnodes(".//input | .//textarea | .//select");
    for my $input (@inputs) {
        my $name = $input->attr("name");
        next unless defined $name;
        
        my $tag = $input->tag;
        if ($tag eq "textarea") {
            $form_data{$name} = $element->as_trimmed_text();
        }
        elsif ($tag eq "select") {
            my @selected = $element->look_down("_tag", "option", "selected", undef);
            if (@selected) {
                $form_data{$name} = $selected[0]->attr("value");
            }
            elsif (my $first = $element->find("option")) {
                $form_data{$name} = $first->attr("value");
            }
        }
        else {
            $form_data{$name} = $input->attr("value");
        }
    }
    
    return %form_data;
}

{
    my %VALID_PROPERTY = make_property_map(qw(value));

    sub get_optionelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        
        return;
    }
}

{
    sub get_inputelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr("value")) if $property eq "value";

        return $element->look_up("_tag", "form") if $property eq "form";
        
        return;
    }
}

1;
__END__

=head1 NAME

Serengeti::Backend::Native::HTMLFormElement - Deals with properties and methods 
of forms

=head1 INTERFACE

=head2 METHODS

=over 4

=item get_property ($element : HTML::Element, $property : scalar) : scalar

Returns the property value from the element when requested from JavaScript.

B<Object properties:>

=over 4

=item elements

Scans the element for any descendants which are input-, textarea- or select-
elements and wraps these in a HTMLCollection element.

=item length

Returns the number of inputs that are descendants of the form.

=item name

Returns the name of the form.

=item enctype

Returns the encodning type of the form when sent - normally this is 
C<application/x-www-form-urlencoded> but if the form contains a file-input 
the type will be C<mulitpart/form-data>.

=item action

Returns the URL which the request will be made to when submitting.

=item target

Returns the name of the frame which will be used to do the submit in.

=item method

Returns the method the submit will be done in. When actually submitting the 
only values permitted are POST and GET. If it's neither a GET request will be 
assumed.

=item submit

Returns a function that can be called to perform the actual submit. The 
function optionally takes a C<object>-instance whose key/value paris can 
override values set on the forms inputs.

=item reset

Returns a function which resets the form to its initial state.

=back

=item submit ( $element : HTML::Element : $override : hash ) : Serengeti::Backend::Native::Document

Gathers the values of the inputs in the form and performs the request. 
Returns a new document instance corresponding to the newly requested page.

=back

=cut