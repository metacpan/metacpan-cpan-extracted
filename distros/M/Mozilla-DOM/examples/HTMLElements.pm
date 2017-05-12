# This example shows how to use the HTMLElement classes,
# in particular for an HTMLSelectElement.
# Refer also to the Elements example.
#
# $CVSHeader: Mozilla-DOM/examples/HTMLElements.pm,v 1.4 2007-06-06 21:46:56 slanning Exp $


package HTMLElements;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.20';   # for HTML*Element classes

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();

    $embed->signal_connect(net_stop => \&net_stop_cb);

    $self->add($embed);
    my $cwd = getcwd();
    $embed->load_url("file://$cwd/index.html");
    $self->{_embed} = $embed;
}


sub net_stop_cb {
    my $embed = shift;

    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;
    my $doc = $window->GetDocument;
    my $docelem = $doc->GetDocumentElement;

    # Get the select element (I've omitted error checking)
#    my $selectlist = $docelem->GetElementsByTagName('select');
#    my $selectnode = $selectlist->Item(0);
    my @selectelement = $docelem->GetElementsByTagName('select');

    # $selectelement[0] is an Element, so we have to switch it
    # to HTMLSelectElement before calling any of its methods.
    my $siid = Mozilla::DOM::HTMLSelectElement->GetIID;
    my $select = $selectelement[0]->QueryInterface($siid);

    # Showing how to select an option, among other things
    my $numopts = $select->GetLength;
    my $optselected = $select->GetSelectedIndex;
    my $optlist = $select->GetOptions;

    print "select has $numopts options, ",
      "option $optselected is selected\n";
    _dump_options($optlist);

    $select->SetSelectedIndex(2);

    print "selected option 2\n";
    _dump_options($optlist);
}

sub _dump_options {
    my $optlist = shift;

    foreach my $i (0 .. $optlist->GetLength - 1) {
        my $optnode = $optlist->Item($i);
        my $oiid = Mozilla::DOM::HTMLOptionElement->GetIID;
        my $opt = $optnode->QueryInterface($oiid);

        print "option $i:\n",
          "\tvalue=", $opt->GetValue, $/,
          "\ttext=", $opt->GetText, $/,
          "\tselected=", ($opt->GetSelected ? 't' : 'f'), $/;
    }
}


1;

__END__

I only demonstrated HTMLSelectElement, but there are 53 subclasses
of HTMLElement. HTMLElement itself is a subclass of Element,
which is a subclass of Node.

Here is a list of HTML*Element classes:

Mozilla::DOM::HTMLAnchorElement
Mozilla::DOM::HTMLAppletElement
Mozilla::DOM::HTMLAreaElement
Mozilla::DOM::HTMLBRElement
Mozilla::DOM::HTMLBaseElement
Mozilla::DOM::HTMLBaseFontElement
Mozilla::DOM::HTMLBodyElement
Mozilla::DOM::HTMLButtonElement
Mozilla::DOM::HTMLDListElement
Mozilla::DOM::HTMLDirectoryElement
Mozilla::DOM::HTMLDivElement
Mozilla::DOM::HTMLElement
Mozilla::DOM::HTMLEmbedElement
Mozilla::DOM::HTMLFieldSetElement
Mozilla::DOM::HTMLFontElement
Mozilla::DOM::HTMLFormElement
Mozilla::DOM::HTMLFrameElement
Mozilla::DOM::HTMLFrameSetElement
Mozilla::DOM::HTMLHRElement
Mozilla::DOM::HTMLHeadElement
Mozilla::DOM::HTMLHeadingElement
Mozilla::DOM::HTMLHtmlElement   # different from HTMLElement
Mozilla::DOM::HTMLIFrameElement
Mozilla::DOM::HTMLImageElement
Mozilla::DOM::HTMLInputElement
Mozilla::DOM::HTMLIsIndexElement
Mozilla::DOM::HTMLLIElement
Mozilla::DOM::HTMLLabelElement
Mozilla::DOM::HTMLLegendElement
Mozilla::DOM::HTMLLinkElement
Mozilla::DOM::HTMLMapElement
Mozilla::DOM::HTMLMenuElement
Mozilla::DOM::HTMLMetaElement
Mozilla::DOM::HTMLModElement
Mozilla::DOM::HTMLOListElement
Mozilla::DOM::HTMLObjectElement
Mozilla::DOM::HTMLOptGroupElement
Mozilla::DOM::HTMLOptionElement
Mozilla::DOM::HTMLParagraphElement
Mozilla::DOM::HTMLParamElement
Mozilla::DOM::HTMLPreElement
Mozilla::DOM::HTMLQuoteElement
Mozilla::DOM::HTMLScriptElement
Mozilla::DOM::HTMLSelectElement
Mozilla::DOM::HTMLStyleElement
Mozilla::DOM::HTMLTableCaptionElement
Mozilla::DOM::HTMLTableCellElement
Mozilla::DOM::HTMLTableColElement
Mozilla::DOM::HTMLTableElement
Mozilla::DOM::HTMLTableRowElement
Mozilla::DOM::HTMLTableSectionElement
Mozilla::DOM::HTMLTextAreaElement
Mozilla::DOM::HTMLTitleElement
Mozilla::DOM::HTMLUListElement


I made this table of events that can occur on HTML elements,
from section 18.2.3 of the HTML 4.1 specification:

Anchor: focus, blur
Area: focus, blur
Body: load, unload
Button: focus, blur
Form: submit
FrameSet: load, unload
Input: focus, blur, select, change
Label: focus, blur
Select: focus, blur, change
TextArea: focus, blur, select, change
Most elements: click, dblclick, mousedown, mouseup, mouseover,
  mousemove, mouseout, keypress, keydown, keyup
