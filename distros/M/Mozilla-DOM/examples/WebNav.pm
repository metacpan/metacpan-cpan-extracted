# This example demonstrates WebNavigation.
#
# $CVSHeader: Mozilla-DOM/examples/WebNav.pm,v 1.3 2007-06-06 21:46:56 slanning Exp $


package WebNav;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.14';   # for WebNavigation
use Mozilla::DOM::WebNavigation qw(:flags);

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    print "LOAD_FLAGS_MASK=", LOAD_FLAGS_MASK, $/;

    my $embed = Gtk2::MozEmbed->new();
    $embed->signal_connect(net_stop => \&net_stop_cb);

    # This demonstrates navigating the session history
    # with keypress events.
    $embed->signal_connect(dom_key_press => \&dom_key_press_cb);

    # This allows popup windows (c.f. BrowserObjects.pm).
    $embed->signal_connect(new_window => sub {
        my ($embed, $chrome) = @_;
        my $newwin = WebNav->new();
        $newwin->set_default_size(600, 400);
        $newwin->show_all();
        return $newwin->{_embed};
    });

    $self->add($embed);

    my $cwd = getcwd();
    $embed->load_url("file://$cwd/webnav1.html");

    $self->{_embed} = $embed;
}

sub net_stop_cb {
    my $embed = shift;

    my $nav = _get_nav($embed);

    # GetSpec gets the full URI; you can use other methods
    # to get specific parts of the URI.
    my $uriobj = $nav->GetCurrentURI;
    my $uri = defined($uriobj) ? $uriobj->GetSpec : '';
    my $charset = defined($uriobj) ? $uriobj->GetOriginCharset : '';

    my $refererobj = $nav->GetReferringURI;
    my $referer = defined($refererobj) ? $refererobj->GetSpec : '';

    print "URI: $uri\n";
    print "referer: $referer\n";
    print "charset: $charset\n";
    print "can go back? ", ($nav->GetCanGoBack ? 'yes' : 'no'), $/;
    print "can go forward? ", ($nav->GetCanGoForward ? 'yes' : 'no'), $/;
}

sub dom_key_press_cb {
    my ($embed, $event) = @_;

    my $nav = _get_nav($embed);

    my $num = join('|', map(ord, '1' .. '9'));
    my $code = $event->GetCharCode;

    if ($code == ord('b')) {
        $nav->GoBack();
    } elsif ($code == ord('f')) {
        $nav->GoForward();
    } elsif ($code =~ /^($num)$/) {
        my $i = $code - ord('1');
        $nav->GotoIndex($i);
    }

    return FALSE;
}


## Helper functions

sub _get_nav {
    my $embed = shift;

    my $browser = $embed->get_nsIWebBrowser;
    my $iid = Mozilla::DOM::WebNavigation->GetIID;
    my $nav = $browser->QueryInterface($iid);

    return $nav;
}


1;
