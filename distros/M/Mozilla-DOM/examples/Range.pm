# This example shows how to use the DocumentRange and Range classes.
# [incomplete - not sure really how useful it is]
#
# $CVSHeader$


package Range;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.18';   # for DocumentRange

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
    my $selection = $window->GetSelection;
    my $doc = $window->GetDocument;
    my $docelem = $doc->GetDocumentElement;

    my $eiid = Mozilla::DOM::NSHTMLElement->GetIID;
    my $nshtmlelement = $docelem->QueryInterface($eiid);

    # Switch to DocumentRange interface from Document
    my $iid = Mozilla::DOM::DocumentRange->GetIID;
    my $docrange = $doc->QueryInterface($iid);

    # Create a range (var range = document.createRange();)
    # See section 2.3 of the DOM Range specification.
    my $range = $docrange->CreateRange();
    $range->SelectNode($docelem);

    # Print out the *text* of the selected nodes
    # (no markup)
    $selection->AddRange($range);
    print $selection->ToString, $/;
}


1;
