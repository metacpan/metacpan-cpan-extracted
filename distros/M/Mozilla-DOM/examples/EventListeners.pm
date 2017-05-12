# NB: to use EventListeners, you have to specifically enable them
# when building Mozilla::DOM (this example won't work otherwise).
# See README for how to enable experimental features.
#
# This example shows how to create event listeners.
# (Click on the button.)
# Refer also to the Minilla, Signals, Elements, and Events examples.
#
# $CVSHeader: Mozilla-DOM/examples/EventListeners.pm,v 1.4 2007-06-06 21:46:56 slanning Exp $


package EventListeners;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.12';   # for EventListener

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();

    $embed->signal_connect(net_stop => \&net_stop_cb);

    $self->add($embed);

    my $cwd = getcwd();
    $embed->load_url("file://$cwd/index.html");

    $self->{_embed} = $embed;

    # See the perldoc for Mozilla::DOM::EventListener for why
    # this is considered experimental. Briefly, you must make
    # sure that your EventListener doesn't go out of scope
    # while HandleEvent can be called on it; otherwise, a segfault
    # will occur. (You could also put the listener in a global variable.)
    $self->{_embed}{listener} = Mozilla::DOM::EventListener->new(\&click_listener);
}


sub net_stop_cb {
    my $embed = shift;

    # Get <input type="button">
    my $button = _get_input($embed, 'button');

    # Usual interface switching, from Node to EventTarget
    my $iid = Mozilla::DOM::EventTarget->GetIID;
    my $target = $button->QueryInterface($iid);

    # Add the event listener created in INIT_INSTANCE above
    $target->AddEventListener('click', $embed->{listener}, 0);

    return TRUE;
}

# This is invoked when you click on the button.
# It only fires after you close the popup alert box, however.
# I think the reason is that the popup window is also
# called as a result of a click-event handler, and that
# handler only returns after the alert box is gone
# (i.e., the `alert' function has returned). But I thought
# only one handler could be added per event type. Maybe this
# means one handler in addition to any handler added by JavaScript
# as an onClick handler, but I'm not sure.
sub click_listener {
    my $event = shift;

    my $type = $event->GetType;
    print "handling event type=$type\n";

    # You could call StopPropagation or PreventDefault here,
    # or maybe QueryInterface to MouseEvent call one of those
    # methods. You could also call RemoveEventListener if you
    # had the EventTarget.

    return TRUE;
}

## Helper functions

# (Same method as in Events.pm, copied out of laziness.)
# If we wanted the 3rd button (<input type="button">),
# $type eq 'button' and $num == 2.
# Returns the input element node.
sub _get_input {
    my ($embed, $type, $num) = @_;
    $num = 0 unless defined $num;

    my @nodes = ();

    # Get all <input> elements
    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;
    my $doc = $window->GetDocument;
    my $docelem = $doc->GetDocumentElement;
    my $inputs = $docelem->GetElementsByTagName('input');

    # Find inputs whose 'type' attribute eq $type
    # and put them in @nodes
    INPUT: foreach my $i (0 .. $inputs->GetLength - 1) {
        my $input = $inputs->Item($i);
        my $attrs = $input->GetAttributes;

        ATTR: foreach my $a (0 .. $attrs->GetLength - 1) {
            my $attr = $attrs->Item($a);
            next ATTR unless $attr->GetNodeName =~ /^type$/i;

            if ($attr->GetNodeValue =~ /^$type$/i) {
                push @nodes, $input;
                next INPUT;
            }
        }
    }

    # This could easily be made to return multiple inputs, instead
    if (@nodes) {
        if (exists $nodes[$num]) {
            return $nodes[$num];
        } else {
            die "not enough $type inputs!\n";
        }
    } else {
        die "no inputs of type=$type\n";
    }
}


1;
