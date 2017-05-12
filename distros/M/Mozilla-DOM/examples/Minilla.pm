# This is a minimal example of using Gtk2::MozEmbed, basically
# a stripped-down pumzilla. It displays your home directory
# and has no extra signal handlers or chrome. This is for comparing
# to the other examples to see what they add. It does nothing
# related to Mozilla::DOM.
#
# $CVSHeader: Mozilla-DOM/examples/Minilla.pm,v 1.4 2007-06-06 21:46:56 slanning Exp $


package Minilla;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2;
use Gtk2::MozEmbed;

# The Minilla class is a subclass of Gtk2::Window.
# We will embed a Gtk2::MozEmbed widget in it.
# (Note: this must be called after `use Gtk2'.)
use Glib::Object::Subclass Gtk2::Window::;

# This is for Glib::Object::Subclass. It initializes
# the window object, in particular adding the mozembed object.
sub INIT_INSTANCE {
    my $self = shift;

    # Create a GtkMozEmbed widget.
    my $embed = Gtk2::MozEmbed->new();

    # Loading a page shows that it's working.
    $embed->load_url("file://$ENV{HOME}");

    # Gtk2::Window isa Gtk2::Container, so we can add
    # the mozembed widget to it.
    $self->add($embed);

    # We could access the mozembed widget using `get_children'
    # and so on, but it's more convenient to save it in the Window object.
    $self->{_embed} = $embed;
}


1;
