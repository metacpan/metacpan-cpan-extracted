package POE::Component::IRC::Plugin::HTML::ElementInfo;

use warnings;
use strict;

our $VERSION = '2.001003'; # VERSION

use base 'POE::Component::IRC::Plugin::BaseWrap';

my %Data = _make_load_data();

sub _make_default_args {
    return (
        trigger          => qr/^html\s+(?=\S+$)/i,
        response_event   => 'irc_html_info',
        out_format       => '[[el]] [[[dtd]]] is [l[empty]] and '
                           . '[l[deprecated]]. Start tag is [l[start_tag]].'
                           . ' End tag is [l[end_tag]]. '
                           . 'Description: [l[description]].',
    );
}

sub _make_response_message {
    my ( $self, $in_ref ) = @_;
    my $nick = (split /!/, $in_ref->{who})[0];
    return [ "$nick, " . $self->_make_data( $in_ref->{what} ) ];
}

sub _make_response_event {
    my ( $self, $in_ref ) = @_;
    $in_ref->{out} = $self->_make_data( $in_ref->{what} );
    return $in_ref;
}

sub _make_data {
    my ( $self, $element ) = @_;

    $element =~ s/^\s+|\s+$//g;
    $element = lc $element;

    unless ( exists $Data{ $element } ) {
         # some punks love to give bots garbage trying to drop them..
         # .. cut the junk off
        $element = substr $element, 0, 25;
        return "I don't have information for $element";
    }

    my $data_ref = $Data{ $element };
    $data_ref->{description} = ucfirst $data_ref->{description};
    my $out = $self->{out_format};
    for ( keys %$data_ref ) {
        $out =~ s/\Q[[$_]]/$data_ref->{$_}/g;
        $out =~ s/\Q[l[$_]]/\L$data_ref->{$_}/ig;
    }
    $out =~ s/\Q[[el]]/$element/g;
    $out =~ s/\Q[l[el]]/\L$element/ig;

    return $out;
}

sub _make_load_data {
    return (
        'a' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#anchor#,
        },
        'abbr' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#abbreviated form (e.g., WWW, HTTP, etc.)#,
        },
        'acronym' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#Indicates an acronym (e.g., WAC, radar, etc.)#,
        },
        'address' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#information on author#,
        },
        'applet' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#Java applet#,
        },
        'area' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#client-side image map area#,
        },
        'b' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#bold text style#,
        },
        'base' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#document base URI#,
        },
        'basefont' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#base font size#,
        },
        'bdo' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#I18N BiDi over-ride#,
        },
        'big' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#large text style#,
        },
        'blockquote' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#long quotation#,
        },
        'body' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Optional#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#document body#,
        },
        'br' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#forced line break#,
        },
        'button' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#push button#,
        },
        'caption' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#table caption#,
        },
        'center' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#shorthand for DIV align=center#,
        },
        'cite' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#citation#,
        },
        'code' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#computer code fragment#,
        },
        'col' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#table column#,
        },
        'colgroup' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table column group#,
        },
        'dd' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#definition description#,
        },
        'del' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#deleted text#,
        },
        'dfn' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#instance definition#,
        },
        'dir' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#directory list#,
        },
        'div' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#generic language/style container#,
        },
        'dl' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#definition list#,
        },
        'dt' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#definition term#,
        },
        'em' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#emphasis#,
        },
        'fieldset' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#form control group#,
        },
        'font' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#local change to font#,
        },
        'form' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#interactive form#,
        },
        'frame' => {
            'dtd' => q#Frameset HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#subwindow#,
        },
        'frameset' => {
            'dtd' => q#Frameset HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#window subdivision#,
        },
        'h1' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'h2' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'h3' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'h4' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'h5' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'h6' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#heading#,
        },
        'head' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Optional#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#document head#,
        },
        'hr' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#horizontal rule#,
        },
        'html' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Optional#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#document root element#,
        },
        'i' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#italic text style#,
        },
        'iframe' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#inline subwindow#,
        },
        'img' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#Embedded image#,
        },
        'input' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#form control#,
        },
        'ins' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#inserted text#,
        },
        'isindex' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#single line prompt#,
        },
        'kbd' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#text to be entered by the user#,
        },
        'label' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#form field label text#,
        },
        'legend' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#fieldset legend#,
        },
        'li' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#list item#,
        },
        'link' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#a media-independent link#,
        },
        'map' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#client-side image map#,
        },
        'menu' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#menu list#,
        },
        'meta' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#generic metainformation#,
        },
        'noframes' => {
            'dtd' => q#Frameset HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#alternate content container for non frame-based rendering#,
        },
        'noscript' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#alternate content container for non script-based rendering#,
        },
        'object' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#generic embedded object#,
        },
        'ol' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#ordered list#,
        },
        'optgroup' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#option group#,
        },
        'option' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#selectable choice#,
        },
        'p' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#paragraph#,
        },
        'param' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Empty#,
            'end_tag' => q#Forbidden#,
            'description' => q#named property value#,
        },
        'pre' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#preformatted text#,
        },
        'q' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#short inline quotation#,
        },
        's' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#strike-through text style#,
        },
        'samp' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#sample program output, scripts, etc.#,
        },
        'script' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#script statements#,
        },
        'select' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#option selector#,
        },
        'small' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#small text style#,
        },
        'span' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#generic language/style container#,
        },
        'strike' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#strike-through text#,
        },
        'strong' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#strong emphasis#,
        },
        'style' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#style info#,
        },
        'sub' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#subscript#,
        },
        'sup' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#superscript#,
        },
        'table' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#The TABLE element contains all other elements that specify caption, rows, content, and formatting.#,
        },
        'tbody' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Optional#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table body#,
        },
        'td' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table data cell#,
        },
        'textarea' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#multi-line text field#,
        },
        'tfoot' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table footer#,
        },
        'th' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table header cell#,
        },
        'thead' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table header#,
        },
        'title' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#document title#,
        },
        'tr' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Optional#,
            'description' => q#table row#,
        },
        'tt' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#teletype or monospaced text style#,
        },
        'u' => {
            'dtd' => q#Loose HTML 4.01#,
            'deprecated' => q#Deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#underlined text style#,
        },
        'ul' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#unordered list#,
        },
        'var' => {
            'dtd' => q#HTML 4.01#,
            'deprecated' => q#Not deprecated#,
            'start_tag' => q#Required#,
            'empty' => q#Not empty#,
            'end_tag' => q#Required#,
            'description' => q#instance of a variable or program argument#,
        },
    );
}

1;
__END__

=encoding utf8

=for stopwords DTD Frameset bot privmsg regexen usermask usermasks

=head1 NAME

POE::Component::IRC::Plugin::HTML::ElementInfo - lookup HTML element information from IRC

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::HTML::ElementInfo);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'HTMLInfoBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Lookup HTML element info',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'HTMLInfo' =>
                POE::Component::IRC::Plugin::HTML::ElementInfo->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $_[KERNEL]->post( $_[SENDER] => join => '#zofbot' );
    }


    <Zoffix> HTMLInfoBot, html span
    <HTMLInfoBot> Zoffix, span [HTML 4.01] is not empty and not deprecated.
                  Start tag is required. End tag is required. Description:
                  generic language/style container.
    <Zoffix> HTMLInfoBot, html head
    <HTMLInfoBot> Zoffix, head [HTML 4.01] is not empty and not deprecated.
                  Start tag is optional. End tag is optional. Description:
                  document head.
    <Zoffix> HTMLInfoBot, html u
    <HTMLInfoBot> Zoffix, u [Loose HTML 4.01] is not empty and deprecated.
                  Start tag is required. End tag is required. Description:
                  underlined text style.
    <Zoffix> HTMLInfoBot, html blah
    <HTMLInfoBot> Zoffix, I don't have information for blah

=head1 DESCRIPTION

This module is a L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base. It provides interface to
lookup HTML element information (description, whether or not the element
is deprecated, are opening/closing tags required, etc)

It accepts input from public channel events, C</notice> messages as well
as C</msg> (private messages); although that can be configured at will.

=head1 CONSTRUCTOR

=head2 new

    # plain and simple
    $irc->plugin_add(
        'HTMLInfo' => POE::Component::IRC::Plugin::HTML::ElementInfo->new
    );

    # juicy flavor
    $irc->plugin_add(
        'HTMLInfo' =>
            POE::Component::IRC::Plugin::HTML::ElementInfo->new(
                auto             => 1,
                response_event   => 'irc_html_info',
                banned           => [ qr/aol\.com$/i ],
                root             => [ qr/mah.net$/i ],
                addressed        => 1,
                trigger          => qr/^html\s+(?=\S+$)/i,
                listen_for_input => [ qw(public notice privmsg) ],
                eat              => 1,
                debug            => 0,
                out_format       => '[[el]] [[[dtd]]] is [l[empty]] and '
                                    . '[l[deprecated]]. Start tag is [l[start_tag]].'
                                    . ' End tag is [l[end_tag]]. '
                                    . 'Description: [l[description]].',
            )
    );

The C<new()> method constructs and returns a new
C<POE::Component::IRC::Plugin::HTML::ElementInfo> object suitable to be
fed to L<POE::Component::IRC>'s C<plugin_add> method. The constructor
takes a few arguments, but I<all of them are optional>. B<Note:>
you can change the values for constructor's arguments by accessing
them as keys in plugin's object, i.e.
C<< $plugin_object->{one_of_arguments} = 'blah' >>

The possible arguments/values are as follows:

=head3 auto

    ->new( auto => 0 );

B<Optional>. Takes either true or false values, specifies whether or not
the plugin should auto respond to requests. When the C<auto>
argument is set to a true value plugin will respond to the requesting
person with the results automatically. When the C<auto> argument
is set to a false value plugin will not respond and you will have to
listen to the events emitted by the plugin to retrieve the results (see
EMITTED EVENTS section and C<response_event> argument for details).
B<Defaults to:> C<1>.

=head3 response_event

    ->new( response_event => 'event_name_to_receive_results' );

B<Optional>. Takes a scalar string specifying the name of the event
to emit when the results of the request are ready. See EMITTED EVENTS
section for more information. B<Defaults to:> C<irc_html_info>

=head3 banned

    ->new( banned => [ qr/aol\.com$/i ] );

B<Optional>. Takes an arrayref of regexes as a value. If the usermask
of the person (or thing) making the request matches any of
the regexes listed in the C<banned> arrayref, plugin will ignore the
request. B<Defaults to:> C<[]> (no bans are set).

=head3 root

    ->new( root => [ qr/\Qjust.me.and.my.friend.net\E$/i ] );

B<Optional>. As opposed to C<banned> argument, the C<root> argument
B<allows> access only to people whose usermasks match B<any> of
the regexen you specify in the arrayref the argument takes as a value.
B<By default:> it is not specified. B<Note:> as opposed to C<banned>
specifying an empty arrayref to C<root> argument will restrict
access to everyone.

=head3 trigger

    ->new( trigger => qr/^html\s+(?=\S+$)/i );

B<Optional>. Takes a regex as an argument. Messages matching this
regex will be considered as requests. See also
B<addressed> option below which is enabled by default. B<Note:> the
trigger will be B<removed> from the message, therefore make sure your
trigger doesn't match the actual data that needs to be processed.
B<Defaults to:> C<qr/^html\s+(?=\S+$)/i>

=head3 addressed

    ->new( addressed => 1 );

B<Optional>. Takes either true or false values. When set to a true value
all the public messages must be I<addressed to the bot>. In other words,
if your bot's nickname is C<Nick> and your trigger is
C<qr/^trig\s+/>
you would make the request by saying C<Nick, trig span>.
When addressed mode is turned on, the bot's nickname, including any
whitespace and common punctuation character will be removed before
matching the C<trigger> (see above). When C<addressed> argument it set
to a false value, public messages will only have to match C<trigger> regex
in order to make a request. Note: this argument has no effect on
C</notice> and C</msg> requests. B<Defaults to:> C<1>

=head3 listen_for_input

    ->new( listen_for_input => [ qw(public  notice  privmsg) ] );

B<Optional>. Takes an arrayref as a value which can contain any of the
three elements, namely C<public>, C<notice> and C<privmsg> which indicate
which kind of input plugin should respond to. When the arrayref contains
C<public> element, plugin will respond to requests sent from messages
in public channels (see C<addressed> argument above for specifics). When
the arrayref contains C<notice> element plugin will respond to
requests sent to it via C</notice> messages. When the arrayref contains
C<privmsg> element, the plugin will respond to requests sent
to it via C</msg> (private messages). You can specify any of these. In
other words, setting C<( listen_for_input => [ qr(notice privmsg) ] )>
will enable functionality only via C</notice> and C</msg> messages.
B<Defaults to:> C<[ qw(public  notice  privmsg) ]>

=head3 out_format

    ->new( out_format =>
        '[[el]] [[[dtd]]] is [l[empty]] and '
        . '[l[deprecated]]. Start tag is [l[start_tag]]. End tag is '
        . '[l[end_tag]]. Description: [l[description]].'
    );

This monster argument specifies the format of the output message. As
a value it takes a string with "tags". Those tags will be substituted
by particular bits of information they represent. Tags in format
C<[[tag_name]]> will be replaced as they are and tags in format
C<[l[tag_name]]> (note the 'l') will be replaced by data in all lower case.
In other words if data for tag 'empty' reads "Not empty" the C<[[empty]]>
tag will be replaced by words "Not empty" but C<[l[empty]]> tags will
be replaced by words "not empty". You can duplicate tags if you like.
B<By default> the C<out_format> is set to:

        '[[el]] [[[dtd]]] is [l[empty]] and '
        . '[l[deprecated]]. Start tag is [l[start_tag]]. End tag is '
        . '[l[end_tag]]. Description: [l[description]].'

Which results in message as:

    <HTMLInfoBot> Zoffix, u [Loose HTML 4.01] is not empty and deprecated.
    Start tag is required. End tag is required. Description: underlined
    text style.

Possible tags are as follows:

=head4 C<[[el]]>

Will be replaced by element's name, i.e. what the user gave the plugin
to lookup information for.

=head4 C<[[dtd]]>

Will be replaced with the DTD (Document Type Definition) in which the
element is valid (this would usually be HTML 4.01 Strict, Loose and
Frameset).

=head4 C<[[empty]]>

Will be replaced with words "empty" or "not empty" depending on whether or not the element is an empty element

=head4 C<[[deprecated]]>

Will be replaced with words "deprecated" or "not deprecated" indicating
whether or not the element is deprecated in HTML 4.01 Strict.

=head4 C<[[start_tag]]>

Will be replaced by words "required" or "optional" indicating whether
or not the start tag for this element is required.

=head4 C<[[end_tag]]>

Same as C<[[start_tag]]> except this is for the end tag.

=head4 C<[[description]]>

Will be replaced with element's short description (its purpose)

=head3 eat

    ->new( eat => 0 );

B<Optional>. If set to a false value plugin will return a
C<PCI_EAT_NONE> after
responding. If eat is set to a true value, plugin will return a
C<PCI_EAT_ALL> after responding. See L<POE::Component::IRC::Plugin>
documentation for more information if you are interested. B<Defaults to>:
C<1>

=head3 debug

    ->new( debug => 1 );

B<Optional>. Takes either a true or false value. When C<debug> argument
is set to a true value some debugging information will be printed out.
When C<debug> argument is set to a false value no debug info will be
printed. B<Defaults to:> C<0>.

=head1 EMITTED EVENTS

=head2 response_event

    $VAR1 = {
        'out' => 'span [HTML 4.01] is not empty and not deprecated. Start
        tag is required. End tag is required. Description: generic
        language/style container.',
        'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix',
        'what' => 'span',
        'type' => 'public',
        'channel' => '#zofbot',
        'message' => 'HTMLInfoBot, html span'
    };

The event handler set up to handle the event, name of which you've
specified in the C<response_event> argument to the constructor
(it defaults to C<irc_html_info>) will receive input
every time request is completed. The input will come in C<$_[ARG0]> in
a form of a hashref.
The keys/value of that hashref are as follows:

=head3 out

    { 'out' => 'span [HTML 4.01] is not empty and not deprecated. Start
            tag is required. End tag is required. Description: generic
            language/style container.' }

The C<out> key will contain the "information message", this will be
your C<out_format> (see constructor) string filled with bits of information
and this will be what will be sent to IRC if C<auto> argument to constructor
is set to a true value.

=head3 what

    { 'what' => 'span' }

The C<what> key will contain the name of the element which was looked up.

=head3 who

    { 'who' => 'Zoffix!n=Zoffix@unaffiliated/zoffix' }

The C<who> key will contain the usermask of the user who sent the request.

=head3 type

    { 'type' => 'public' }

The C<type> key will contain the "type" of the message sent by the
requester. The possible values are: C<public>, C<notice> and C<privmsg>
indicating that request was requested in public channel, via C</notice>
and via C</msg> (private message) respectively.

=head3 channel

    { 'channel' => '#zofbot' }

The C<channel> key will contain the name of the channel from which the
request
came from. This will only make sense when C<type> key (see above) contains
C<public>.

=head3 message

    { 'message' => 'HTMLInfoBot, html span' }

The C<message> key will contain the message which the user has
sent to request.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut