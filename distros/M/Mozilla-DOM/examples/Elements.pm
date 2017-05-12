# This example shows how to access DOM elements.
# Refer also to the Minilla and Signals examples.
#
# $CVSHeader: Mozilla-DOM/examples/Elements.pm,v 1.5 2007-06-06 21:46:56 slanning Exp $


package Elements;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.20';
use Mozilla::DOM::Node qw(:types);

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    print "TEXT_NODE=", TEXT_NODE, $/;

    my $embed = Gtk2::MozEmbed->new();

    # The net_stop signal fires when a page stops loading,
    # so we can connect our DOM-manipulating code to that.
    $embed->signal_connect(net_stop => \&net_stop_cb);

    $self->add($embed);
    $embed->load_url('about:blank');
    $self->{_embed} = $embed;

    # You'll probably be tempted to call get_nsIWebBrowser, etc.,
    # here to stuff them into $self, but don't -- the window doesn't
    # exist until you do `show_all' on it (we're still in INIT_INSTANCE
    # here), so the Gtk2::MozEmbed widget doesn't exist yet, so at
    # best you'll get undef (at worst, a segfault).
}


sub net_stop_cb {
    my $embed = shift;

    # Mozilla::DOM::WebBrowser
    my $browser = $embed->get_nsIWebBrowser;

    # Mozilla::DOM::Window (window object in JavaScript)
    my $window = $browser->GetContentDOMWindow;

    # Mozilla::DOM::Document (document object in JavaScript)
    # This is the Document in "Document Object Model".
    # Using this you can create all Elements/Nodes.
    my $doc = $window->GetDocument;

    # Mozilla::DOM::Element (<HTML> element)
    my $docelem = $doc->GetDocumentElement;

    print "DocumentElement:\n";
    print "\ttag=", $docelem->GetTagName, $/;

    if ($docelem->HasChildNodes) {
        # Mozilla::DOM::NodeList
        my $bodylist = $docelem->GetElementsByTagName('body');
        if ($bodylist->GetLength) {
            my $body = $bodylist->Item(0);

            # Change body bgcolor attribute (tedious...)
            my $attrnodemap = $body->GetAttributes;
            my $newattr = $doc->CreateAttribute('bgcolor');
            $newattr->SetValue('#dd22dd');
            # (no idea why this is called "named")
            $attrnodemap->SetNamedItem($newattr);

            # Insert some text after all of <body>'s children
            # (though in this case there are no children).
            my $text = $doc->CreateTextNode("Hello, world!");
            $body->InsertBefore($text);
        }

        # Mozilla::DOM::NodeList
        my @kids = $docelem->GetChildNodes;
        foreach my $kid (@kids) {
            # Mozilla::DOM::Node
            print "\tchild: ", $kid->GetNodeName, $/;

            if ($kid->HasAttributes) {
                # Mozilla::NamedNodeMap
                my $attrs = $kid->GetAttributes;

                my $numattrs = $attrs->GetLength;
                foreach my $j (0 .. $numattrs - 1) {
                    # Mozilla::DOM::Node
                    my $attr = $attrs->Item($j);
                    my $name = $attr->GetNodeName;
                    my $val = $attr->GetNodeValue;
                    print "\t\tattr $j: $name=$val\n";
                }
            }
        }
    }

}


1;
