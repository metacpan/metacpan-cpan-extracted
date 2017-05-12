# This example demonstrates the History, Location, and Navigator
# browser objects (Window and Document being two others familiar
# from JavaScript). It also shows Screen, though I don't think
# that's really considered a "browser object".
#
# $CVSHeader: Mozilla-DOM/examples/BrowserObjects.pm,v 1.3 2007-06-06 21:46:56 slanning Exp $


package BrowserObjects;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.13';   # for History, Location, Navigator, Screen

use Glib::Object::Subclass Gtk2::Window::;

# Will set these to zero after they're displayed once,
# since their output is always the same.
my $shownavigator = 1;
my $showscreen = 1;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();

    # This handler dumps information on the browser objects.
    $embed->signal_connect(net_stop => \&net_stop_cb);

    # This one demonstrates History's `Back' method
    # when you double click anywhere.
    $embed->signal_connect(dom_mouse_dbl_click => \&dom_mouse_dbl_click_cb);

    # An extra feature in this demo is allowing popup windows.
    # (This also comes from pumzilla in Gtk2::MozEmbed.)
    # Try commenting this out, then clicking on the link;
    # nothing will happen.
    $embed->signal_connect(new_window => sub {
        my ($embed, $chrome) = @_;

        my $newwin = BrowserObjects->new();
        $newwin->set_default_size(600, 400);
        $newwin->show_all();

        # As usual, return the embedded widget, not the window
        return $newwin->{_embed};
    });

    $self->add($embed);

    my $cwd = getcwd();
    $embed->load_url("file://$cwd/index2.html");

    $self->{_embed} = $embed;
}

sub net_stop_cb {
    my $embed = shift;

    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;

    my $iid = Mozilla::DOM::WindowInternal->GetIID;
    my $windowinternal = $window->QueryInterface($iid);

    show_location($windowinternal);
    show_history($windowinternal);
    show_navigator($windowinternal) if $shownavigator;
    show_screen($windowinternal) if $showscreen;

    print "=========\n";
}

sub dom_mouse_dbl_click_cb {
    my ($embed, $event) = @_;

    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;

    my $iid = Mozilla::DOM::WindowInternal->GetIID;
    my $windowinternal = $window->QueryInterface($iid);
    my $history = $windowinternal->GetHistory;

    $history->Back();

    return FALSE;
}

## Helper functions

sub show_location {
    my $windowinternal = shift;

    my $location = $windowinternal->GetLocation;

    print "Location:\n";

    # Each of these also has a Set version.
    # I don't know what Hash or Search are.
    foreach my $prop (qw(Hash Host Hostname Href Pathname
                         Port Protocol Search))
    {
        my $method = "Get$prop";
        my $val = $location->$method;
        print "\t$prop = $val\n";
    }

    # There are also Reload, Replace, Assign, and ToString (?) methods
}

sub show_history {
    my $windowinternal = shift;

    my $history = $windowinternal->GetHistory;

    print "History:\n";

    foreach my $prop (qw(Length Current Previous Next))
    {
        my $method = "Get$prop";
        my $val = $history->$method;
        print "\t$prop = $val\n";
    }

    # There are also Back, Forward, Go, and Item methods.
    # The Back method is shown in dom_mouse_dbl_click_cb.
}

sub show_navigator {
    my $windowinternal = shift;

    my $nav = $windowinternal->GetNavigator;

    print "Navigator:\n";

    foreach my $prop (qw(AppCodeName AppName AppVersion Language
                         Platform Oscpu Vendor VendorSub
                         Product ProductSub SecurityPolicy UserAgent))
    {
        my $method = "Get$prop";
        my $val = $nav->$method;
        print "\t$prop = $val\n";
    }

    foreach my $prop (qw(CookieEnabled JavaEnabled TaintEnabled)) {
        my $method = ($prop eq 'CookieEnabled') ? "Get$prop" : $prop;
        my $val = ($nav->$method) ? 't' : 'f';
        print "\t$prop = $val\n";
    }

    $shownavigator = 0;
}

sub show_screen {
    my $windowinternal = shift;

    my $screen = $windowinternal->GetScreen;

    print "Screen:\n";

    foreach my $prop (qw(Top Left Width Height
                         AvailWidth AvailHeight AvailLeft AvailTop
                         PixelDepth ColorDepth))
    {
        my $method = "Get$prop";
        my $val = $screen->$method;
        print "\t$prop = $val\n";
    }

    $showscreen = 0;
}


1;
