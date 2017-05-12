# This example shows how to use Window scroll methods.
# Refer also to the Minilla and Signals examples.
#
# $CVSHeader: Mozilla-DOM/examples/Scroll.pm,v 1.1 2007-06-06 21:46:56 slanning Exp $

package Scroll;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.06';
use Mozilla::DOM '0.21';

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();

    $embed->signal_connect(net_stop => \&net_stop_cb);

    $self->add($embed);
    my $cwd = getcwd();
    $embed->load_url("file://$cwd/scroll.html");
    $self->{_embed} = $embed;
}


sub net_stop_cb {
    my $embed = shift;

    # Mozilla::DOM::WebBrowser
    my $browser = $embed->get_nsIWebBrowser;

    # Mozilla::DOM::Window (window object in JavaScript)
    my $window = $browser->GetContentDOMWindow;

    my $scrollx = $window->GetScrollX;
    my $scrolly = $window->GetScrollY;
    print "original scroll x=$scrollx, y=$scrolly\n";
    sleep 1;

    $window->ScrollTo(16, 32);
    $scrollx = $window->GetScrollX;
    $scrolly = $window->GetScrollY;
    print "ScrollTo(16,32): x=$scrollx, y=$scrolly\n";
    sleep 1;

    $window->ScrollBy(32, 32);
    $scrollx = $window->GetScrollX;
    $scrolly = $window->GetScrollY;
    print "ScrollBy(32,32): x=$scrollx, y=$scrolly\n";
    sleep 1;

    $window->ScrollByLines(3);
    $scrollx = $window->GetScrollX;
    $scrolly = $window->GetScrollY;
    print "ScrollByLines(3): x=$scrollx, y=$scrolly\n";
    sleep 1;

    $window->ScrollByPages(1);
    $scrollx = $window->GetScrollX;
    $scrolly = $window->GetScrollY;
    print "ScrollByPages(1): x=$scrollx, y=$scrolly\n";
    sleep 1;

    exit;
}

1;
