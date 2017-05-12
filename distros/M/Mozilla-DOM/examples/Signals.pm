# This example is a step above Minilla, showing all of the signals
# that can be used from Gtk2::MozEmbed. Comments already noted in
# Minilla are omitted.
#
# $CVSHeader: Mozilla-DOM/examples/Signals.pm,v 1.4 2007-06-06 21:46:56 slanning Exp $


package Signals;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed '0.04';

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    my $embed = Gtk2::MozEmbed->new();
    $embed->load_url("file://$ENV{HOME}");

    # List of all signals in GtkMozEmbed. Some of them are lacking
    # signal marshallers (functions to convert arguments from C to Perl)
    # in Gtk2::MozEmbed, so they won't be as useful as they could be.
    # The signal handlers are below.
    my @signals = qw(link_message js_status location title progress progress_all
                     net_state net_state_all net_start net_stop new_window
                     visibility destroy_browser open_uri size_to dom_key_down
                     dom_key_press dom_key_up dom_mouse_down dom_mouse_up
                     dom_mouse_click dom_mouse_dbl_click dom_mouse_over
                     dom_mouse_out security_change status_change);
    foreach my $sig (@signals) {
        my $cb = \&{$sig . '_cb'};
        $embed->signal_connect($sig => sub {print "$sig\n"; $cb->(@_)});
        # or for example
        # $embed->signal_connect($sig => $cb);
        # or simply
        # $embed->signal_connect($sig => sub {print "$sig\n"});
    }

    $self->add($embed);
    $self->{_embed} = $embed;
}


## Signal handlers

# When the link message changes. This happens when
# the user moves the mouse over a link in a web page.
sub link_message_cb {
    my $embed = shift;
    print "\tlink_message=", $embed->get_link_message, $/;
}

# When the JavaScript status message changes.
sub js_status_cb {
    my $embed = shift;
    print "\tjs_status=", $embed->get_js_status, $/;
}

# When the location of the document changes.
sub location_cb {
    my $embed = shift;
    print "\tlocation=", $embed->get_location, $/;
}

# When the title of a document changes.
sub title_cb {
    my $embed = shift;
    print "\ttitle=", $embed->get_title, $/;
}

# When there is a change in the progress of loading a document.
# The cur value indicates how much of the document has been downloaded.
# The max value indicates the length of the document. If the value of
# max is less than one the full length of the document can not be determined.
sub progress_cb {
    my ($embed, $cur, $max) = @_;
    print "\tcur=$cur\n\tmax=$max\n";
}

#  void (* progress_all)        (GtkMozEmbed *embed, const char *aURI,
#				gint curprogress, gint maxprogress);
sub progress_all_cb {
    my ($embed, $uri, $cur, $max) = @_;
    print "\tcur=$cur\n\tmax=$max\n\turi=$uri\n";
}

# When there's a change in the state of the loading of a document.
sub net_state_cb {
    my ($embed, $state_flags, $status) = @_;
    print "\tflags=$state_flags\n\tstatus=$status\n";
}

#  void (* net_state_all)       (GtkMozEmbed *embed, const char *aURI,
#				gint state, guint status);
sub net_state_all_cb {
    my ($embed, $uri, $state_flags, $status) = @_;
    print "\turi=$uri\n\tflags=$state_flags\n\tstatus=$status\n";
}

# When the loading of a document starts.
sub net_start_cb {
    my $embed = shift;

}

# When the loading of a document completes.
sub net_stop_cb {
    my $embed = shift;

}

# When a new toplevel window is requested by the document.
# This will happen in the case of a window.open() in JavaScript.
# Responding to this signal allows you to surround a new toplevel
# window with your chrome.
# You should return the newly created GtkMozEmbed object.
sub new_window_cb {
    my ($embed, $chromemask) = @_;

    my $newwin = __PACKAGE__->new(chrome => $chromemask);
    $newwin->set_default_size(600, 400);
    $newwin->show_all();

    # NB: we return the GtkMozEmbed widget inside the window,
    # not the new window itself.
    return $newwin->{_embed};
}

# When the toplevel window in question needs to be shown or hidden.
# If the visibility argument is I<TRUE> then the window should be
# shown. If it's I<FALSE> it should be hidden.
sub visibility_cb {
    my ($embed, $visibility) = @_;
    print "\tvisibility=", ($visibility ? 'true' : 'false'), $/;
}

# When the document requests that the toplevel window be closed.
# This will happen in the case of a JavaScript window.close().
sub destroy_browser_cb {
    my $embed = shift;
}

# When the document tries to load a new document, for example when
# someone clicks on a link in a web page. This signal gives the
# embedder the opportunity to keep the new document from being loaded.
# The uri argument is the URI that's going to be loaded.
# If you return TRUE from this signal, the new document will NOT
# be loaded. If you return FALSE the new document will be loaded.
sub open_uri_cb {
    my ($embed, $uri) = @_;
    print "\tURI=$uri\n";

    return FALSE;
}

# I'm not sure if this works with Gtk2::MozEmbed.
sub size_to_cb {
    my ($embed, $width, $height) = @_;
    print "\twidth=$width\n\theight=$height\n";
}

# When a key is pressed down.
# $event is a Mozilla::DOM::KeyEvent.
sub dom_key_down_cb {
    my ($embed, $event) = @_;
    _dump_key_event($event);
    return FALSE;
}

# When a key is pressed and released.
# $event is a Mozilla::DOM::KeyEvent.
sub dom_key_press_cb {
    my ($embed, $event) = @_;
    _dump_key_event($event);
    return FALSE;
}

# When a key is released.
# $event is a Mozilla::DOM::KeyEvent.
sub dom_key_up_cb {
    my ($embed, $event) = @_;
    _dump_key_event($event);
    return FALSE;
}

# When the mouse button is pressed.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_down_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}

# When the mouse button is released.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_up_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}

# When the mouse button is pressed and released.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_click_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}

# When the mouse button is quickly clicked twice.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_dbl_click_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}

# When the mouse cursor moves onto an element.
# In the case of nested elements, this event type is always targeted
# at the most deeply nested element.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_over_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}

# When the mouse cursor moves out of an element.
# In the case of nested elements, this event type is always targeted
# at the most deeply nested element.
# $event is a Mozilla::DOM::MouseEvent.
sub dom_mouse_out_cb {
    my ($embed, $event) = @_;
    _dump_mouse_event($event);
    return FALSE;
}


sub security_change_cb {
    my ($embed, $request, $state) = @_;
}
sub status_change {
    my ($embed, $request, $status, $message) = @_;
}


## Helper functions

sub _dump_mouse_event {
    my $event = shift;

    if (ref $event) {
        my $type = $event->GetType();
        print "\tType: $type\n";

        # Properties are not only from Mozilla::DOM::MouseEvent,
        # but also Mozilla::DOM::UIEvent and Mozilla::DOM::Event.
        foreach my $prop (qw(ScreenX ScreenY ClientX ClientY
                             CtrlKey ShiftKey AltKey MetaKey Button
                             EventPhase Bubbles Cancelable
                             Detail))
        {
            # Button and Detail properties only make sense
            # for mouse clicks.
            next if ($prop eq 'Button' or $prop eq 'Detail')
              and ($type eq 'mouseover' or $type eq 'mouseout');

            my $method = "Get$prop";
            my $val = $event->$method;
            print "\t$prop: '$val'\n";
        }
    }
}

sub _dump_key_event {
    my $event = shift;

    if (ref $event) {
        # Properties are not only from Mozilla::DOM::KeyEvent,
        # but also Mozilla::DOM::UIEvent and Mozilla::DOM::Event.
        foreach my $prop (qw(CharCode KeyCode
                             CtrlKey ShiftKey AltKey MetaKey
                             EventPhase Bubbles Cancelable
                             Type TimeStamp Detail))
        {
            my $method = "Get$prop";
            my $val = $event->$method;
            print "\t$prop: '$val'\n";
        }
    }
}


1;
