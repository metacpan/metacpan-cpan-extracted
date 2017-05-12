package Serengeti::Backend::Native::HTMLElementProperties;

use strict;
use warnings;

use Data::Dumper qw(Dumper);
use Module::Load qw();
use Module::Pluggable require => 0, 
                      search_path => [qw(Serengeti::Backend::Native::Elements)],
                      sub_name => "element_classes";

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(make_property_map to_DOMString);
our @EXPORT_OK = @EXPORT;

sub make_property_map {
    return map { $_ => 1 } @_;
}

sub to_DOMString {
    my $value = shift;
    return "" unless defined $value;
    return $value;
}

my %SHARED_PROPERTY = (
    # HTMLElement
    id          => sub { to_DOMString(shift->attr("id")); },
    title       => sub { to_DOMString(shift->attr("title")); },
    lang        => sub { to_DOMString(shift->attr("lang")); },
    dir         => sub { to_DOMString(shift->attr("dir")); },
    className   => sub { to_DOMString(shift->attr("class")); },
    tagName     => \&get_tag_name,
    innerHTML   => sub { to_DOMString(shift->as_HTML); },
    textValue   => sub { to_DOMString(shift->as_trimmed_text); },
    
    # Node elements
    parentNode  => sub { shift->parent },
    childNodes  => sub { 
        my $element = shift;
        my @children = $element->content_list;
        return Serengeti::Backend::Native::HTMLCollection->new(@children);
    },
    firstChild => sub { (shift->content_list)[0] },
    lastChild => sub { (shift->content_list)[-1] },
    previousSibling => sub { shift->getPreviousSibling },
    nextSibling => sub { shift->getNextSibling },
    ownerDocument => sub { shift->root->owner_document },
);

my %ELEMENT_HANDLER = (
    html    => \&get_htmlelement_property,
    head    => \&get_headelement_property,
    link    => \&get_linkelement_property,
    title   => \&get_titleelement_property,
    meta    => \&get_metaelement_property,
    base    => \&get_baseelement_property,
    frameset => \&get_framesetelement_property,
    frame   => \&get_frameelement_property,
    a       => \&get_anchorelement_property,
    img     => \&get_imageelement_property,
);

for my $class (__PACKAGE__->element_classes) {
    Module::Load::load $class;
    my %handlers = $class->register();
    @ELEMENT_HANDLER{keys %handlers} = values %handlers;
}

# From the HTML DOM level 2 specification
# If the document is an HTML 4.01 document the element type names exposed 
# through a property are in uppercase. For example, the body element type 
# name is exposed through the tagName property as BODY. If the document is 
# an XHTML 1.0 document the element name is exposed as it is written in the 
# XHTML file. This means that the element type names are exposed in lowercase 
# for XHTML documents since the XHTML 1.0 DTDs defines element type names as 
# lowercase, and XHTML, being derived from XML, is case sensitive.
sub get_tag_name {
    my $element = shift;

    # TODO: Implement support for the rules above
    return $element->tag;
}

sub get_property {
    my ($element, $property) = @_;

    if (exists $SHARED_PROPERTY{$property}) {
        return $SHARED_PROPERTY{$property}->($element);
    }
    
    my $h = $ELEMENT_HANDLER{lc $element->tag};
    return unless $h;
    
    return $h->($element, $property); 
}

sub get_htmlelement_property {
    my ($element, $property) = @_;
    
    return "*** this property is deprecated ***" if $property eq "version";
    
    return;
}

sub get_headelement_property {
    my ($element, $property) = @_;

    return to_DOMString($element->attr("profile")) if $property eq "profile";
    
    return;
}

{
    my %VALID_PROPERTY = make_property_map(qw(
        charset 
        href 
        hreflang
        rel
        rev
        target
        type
    ));
    
    sub get_linkelement_property {
        my ($element, $property) = @_;

        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};

        return $element->attr("disabled") ? 1 : '' if $property eq "disabled";
        if ($property eq "media") {
            my $attr_value = $element->attr("media");
            return $attr_value if defined $attr_value;
            return "screen";
        }
        return;
    }
}

sub get_titleelement_property {
    my ($element, $property) = @_;

    return to_DOMString($element->as_text) if $property eq "text";
    
    return;
}

{
    my %VALID_PROPERTY = make_property_map(qw(
        content
        name 
        scheme
    ));
    
    sub get_metaelement_property {
        my ($element, $property) = @_;

        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};

        return $element->attr("http-equiv") if $property eq "httpEquiv";

        return;
    }
}

{
    my %VALID_PROPERTY = make_property_map(qw(href target));
    
    sub get_baseelement_property {
        my ($element, $property) = @_;

        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        return;
    }
}

{
    my %VALID_PROPERTY = make_property_map(qw(cols rows));

    sub get_framesetelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        
        return;
    }
}

{
    my %VALID_PROPERTY = make_property_map(qw(
        frameBorder longDesc marginHeight marginWidth name scrolling src
    ));

    sub get_frameelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        return $element->attr("noResize") ? 1 : '' if $property eq "noResize";
        
        if ($property eq "contentDocument") {
            # Load content unless loaded
            my $doc = $element->attr("contentDocument");
            return $doc if $doc;
            
            my $owner_doc = $element->root->owner_document;
            my $url = $owner_doc->make_url(
                $element->attr("src")
            );
            
            $doc = $owner_doc->browser->get($url, {}, { no_broadcast => 1 });
            
            $element->attr("contentDocument", $doc);

            return $doc;
        }
        
        return;
    }
}

{
    my %VALID_PROPERTY = make_property_map(qw(href name));

    sub get_anchorelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        
        return;
    }
}

{
    my %VALID_PROPERTY = make_property_map(qw(src alt name height width));

    sub get_imageelement_property {
        my ($element, $property) = @_;
        
        return to_DOMString($element->attr($property)) if exists $VALID_PROPERTY{$property};
        
        return;
    }
}

1;