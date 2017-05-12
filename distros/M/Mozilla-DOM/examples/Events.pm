# This example shows how to create events, with a bit of
# DOM calesthenics thrown in.
# Refer also to the Minilla, Signals, and Elements examples.
#
# $CVSHeader: Mozilla-DOM/examples/Events.pm,v 1.5 2007-06-06 21:46:56 slanning Exp $


package Events;

use strict;
use warnings;

use Cwd 'getcwd';
use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';
use Mozilla::DOM '0.17';   # for exporting :phases
#use Mozilla::DOM::Event qw(:phases);  # XXX: need to add examples
#use Mozilla::DOM::KeyEvent qw(:keycodes);
#use Mozilla::DOM::MutationEvent qw(:changes);

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();
    $self->add($embed);

    $embed->signal_connect(net_stop => \&net_stop_cb);
    $embed->signal_connect(dom_mouse_click => \&click_cb);
    $embed->signal_connect(dom_key_press => \&press_cb);

    # XXX: there's got to be a way to refer to a file
    # relative to the cwd using a file:// URI, isn't there?
    my $cwd = getcwd();
    $embed->load_url("file://$cwd/index.html");

    $self->{_embed} = $embed;
    $self->{_lock} = {};
}


sub net_stop_cb {
    my $embed = shift;

    my $click = _create_event($embed, 'MouseEvent', 'click');
    my $button = _get_input($embed, 'button');
    _do_event($click, $button);
}

sub click_cb {
    my ($embed, $event) = @_;

    # Prevent infinite recursion, since we dispatch click
    # events from within the click handler
    return FALSE if _locked($embed, $event);

    # Click the radio buttons
    # XXX: this only displays the last one clicked;
    # and sleeping between events just makes it wait to display.
    # Also, clicking on the buttons manually doesn't refresh the
    # selected one. Can you refresh the Gtk2::Window?
    #   Duhrr, wait a minute.. If I click on a button,
    # then click_cb gets called.. so...
    # I should be doing this stuff in the press_cb.
    my $click = _create_event($embed, 'MouseEvent', 'click');
    foreach my $i (0 .. 2) {
        my $radio = _get_input($embed, 'radio', $i);
        _do_event($click, $radio);
    }

    # Type a random character into the text field
    my $charcode = int(rand(26)) + ord('a');
    my $press = _create_event($embed, 'KeyEvent', 'keypress', $charcode);
    my $textbox = _get_input($embed, 'text');
    _do_event($press, $textbox);

    # See the documentation for Mozilla::DOM::Event InitEvent
    # for more events you can create.

    _unlocked($embed, $event);

    return FALSE;   # I'm not sure this actually does anything...
}

sub press_cb {
    my ($embed, $event) = @_;

    # Prevent infinite recursion if we dispatch keypress
    # events from within the keypress handler
    return FALSE if _locked($embed, $event);

    # Click the 1st option in the select menu
    # (XXX: doesn't seem to work.. Maybe you have to just
    # change the 'selected' attributes?
    # "Select boxes are more difficult. A click event on select boxes
    # or options turns out not to work in all browsers, so I opted for
    # the traditional change event on the select box itself."
    # Is this relevant?
    # change
    # A control loses the input focus and its value has been modified
    # since gaining focus. This event can occur either via a user interface
    # manipulation or the focus() methods and the attributes defined in
    # [DOM Level 2 HTML]. This event is valid for INPUT, SELECT, and
    # TEXTAREA element.)
    my $click = _create_event($embed, 'MouseEvent', 'click');
    my $out = _create_event($embed, 'MouseEvent', 'mouseout');
    my $over = _create_event($embed, 'MouseEvent', 'mouseover');

    my ($select, $option1) = _get_select_option($embed, 'list', 0);
    (undef, my $option2)   = _get_select_option($embed, 'list', 1);

#    _do_event($click, $option2);  # initially selected item
#    _do_event($out, $option2);
#    _do_event($over, $option1);

    _do_event($click, $select);
    _do_event($click, $option1);

    _unlocked($embed, $event);

    return FALSE;   # I'm not sure this actually does anything...
}


# Private functions - probably'd want to subclass Gtk2::MozEmbed, etc.,
# in a real app

sub _create_event {
    my ($embed, $class, $type, $charcode) = @_;

    my $doc = _get_document($embed);

    # You can see if the DOM implementation supports
    # a particular interface, though I don't trust what it says
#    my $impl = $doc->GetImplementation;
#    foreach my $feature (qw(Views MouseEvents KeyEvents UIEvents Events)) {
#        print "Does",
#          ($impl->HasFeature($feature, '2.0') ? '' : ' not'),
#          " support $feature\n";
#    }

    # Create an event
    # First call the GetIID class method to get an ID.
    # Then extract the DocumentEvent interface from the Document
    # by passing the ID to QueryInterface. Finally, create a
    # generic event from it.
    my $iid = Mozilla::DOM::DocumentEvent->GetIID();
    my $docevent = $doc->QueryInterface($iid);
    my $event = $docevent->CreateEvent($class . 's');

    if ($class eq 'MouseEvent') {
        # Initialize the MouseEvent ('click')
        $event->InitEvent($type, 1, 1);
        return $event;
    } elsif ($class eq 'KeyEvent') {
        # 'keypress' events are more complicated because
        # you have to give a character to press. So we have to switch
        # its interface to KeyEvent to call its InitKeyEvent method
        # rather than just initializing it as a generic Event.
        my $kiid = Mozilla::DOM::KeyEvent->GetIID();
        my $keyevent = $event->QueryInterface($kiid);
        $keyevent->InitKeyEvent($type, 1, 1, 0, 0, 0, 0, 0, $charcode);
        return $keyevent;
    } else {
        die "Unknown event class '$class'\n";
    }
}

# If we wanted the 3rd button (<input type="button">),
# $type eq 'button' and $num == 2.
# Returns the input element node.
sub _get_input {
    my ($embed, $type, $num) = @_;
    $num = 0 unless defined $num;

    my @nodes = ();

    # Get all <input> elements
    my $doc = _get_document($embed);
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

# If we wanted the 3rd option of a <select> element
# with name="$name", then $num == 2.
# Returns both the select and option element nodes.
sub _get_select_option {
    my ($embed, $name, $num) = @_;
    $num = 0 unless defined $num;

    # Get all <select> elements
    my $doc = _get_document($embed);
    my $docelem = $doc->GetDocumentElement;
    my $selects = $docelem->GetElementsByTagName('select');

    # Find select whose name attribute matches $name
    my $select = undef;
    SELECT: foreach my $i (0 .. $selects->GetLength - 1) {
        my $input = $selects->Item($i);
        my $attrs = $input->GetAttributes;

        ATTR: foreach my $a (0 .. $attrs->GetLength - 1) {
            my $attr = $attrs->Item($a);
            next ATTR unless $attr->GetNodeName =~ /^name$/i;

            if ($attr->GetNodeValue =~ /^$name$/i) {
                $select = $input;
                last SELECT;
            }
        }
    }
    die "select with name=$name not found\n"
      unless defined $select;

    # Find option number $num
    my $kids = $select->GetChildNodes;
    my $option = 0;
    foreach my $k (0 .. $kids->GetLength - 1) {
        my $kid = $kids->Item($k);
        # Children could be text nodes, etc., so make sure it's an <option>
        next unless $kid->GetNodeName =~ /^option$/i;

        if ($option++ == $num) {
            return ($select, $kid);
        }
    }
    die "option num=$num not found in select name=$name\n";
}

sub _get_document {
    my $embed = shift;
    my $browser = $embed->get_nsIWebBrowser;
    my $window = $browser->GetContentDOMWindow;
    my $doc = $window->GetDocument;
    return $doc;
}

sub _do_event {
    my ($event, $input) = @_;
    my $iid = Mozilla::DOM::EventTarget->GetIID();
    my $target = $input->QueryInterface($iid);
    $target->DispatchEvent($event);
}

# Prevent infinite event recursion
sub _locked {
    my ($embed, $event) = @_;
    return 1 if $embed->{_lock}{ref($event)};
    $embed->{_lock}{ref($event)} = 1;
    return 0;
}
sub _unlocked {
    my ($embed, $event) = @_;
    $embed->{_lock}{ref($event)} = 0;
}


1;
