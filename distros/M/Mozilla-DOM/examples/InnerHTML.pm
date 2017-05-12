# This example shows how to get element.innerHTML,
# which lets you print out HTML nodes as text.
#
# $CVSHeader$


package InnerHTML;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.18';   # for NSHTMLElement

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

    # Get <html> element
    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;

    my $selection = $window->GetSelection;
    my $doc = $window->GetDocument;

# this all works:
#    my $diid = Mozilla::DOM::NSDocument->GetIID;
#    my $nsdoc = $doc->QueryInterface($diid);
#    print "charset=", $nsdoc->GetCharacterSet, $/;
#    print "location=", $nsdoc->GetLocation->ToString, $/;
#    print "contenttype=", $nsdoc->GetContentType, $/;
#    print "title=", $nsdoc->GetTitle, $/;
#    print "lastmod=", $nsdoc->GetLastModified, $/;
#    print "referer=", $nsdoc->GetReferrer, $/;

    my $docelem = $doc->GetDocumentElement;

    print "----------- HTML ------------\n";
    print '<', $docelem->GetNodeName, ' ';
    if ($docelem->HasAttributes) {
        my $attrs = $docelem->GetAttributes;
        for (my $i = 0; $i < $attrs->GetLength; $i++) {
            my $attr = $attrs->Item($i);
            print $attr->GetNodeName, '="', $attr->GetNodeValue, '" ';
        }
    }
    print ">\n";

    # Switch that element to NSHTMLElement interface
    my $eiid = Mozilla::DOM::NSHTMLElement->GetIID;
    my $nshtmlelement = $docelem->QueryInterface($eiid);

    # Print out innerHTML.
    # Unfortunately Mozilla doesn't support outerHTML,
    # so we can't print the whole thing (not to mention
    # the DOCTYPE thing at the top)
    print $nshtmlelement->GetInnerHTML, $/;


    print "\n</html>\n";
}


# maybe need to add DocumentTraversal interface, NodeIterator



1;
