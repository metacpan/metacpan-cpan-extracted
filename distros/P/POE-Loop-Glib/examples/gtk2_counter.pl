#!/usr/bin/perl
use warnings;
use strict;

# Taken from http://poe.perl.org/?POE_Cookbook/Gtk2_Counter

# Gtk support is enabled if the Gtk module is used before POE itself.
# POE::Loop::Glib doesn't initialize Gtk2 (for obvious reasons), so we
# do it here
use Gtk2-init;
use POE::Kernel {loop => "Glib"};
use POE::Session;

# Create the session that will drive the user interface.
POE::Session->create(
  inline_states => {
    _start   => \&ui_start,
    ev_count => \&ui_count,
    ev_clear => \&ui_clear,
    _stop    => sub {},
  }
);

# Run the program until it is exited.
$poe_kernel->run();
exit 0;

# Create the user interface when the session starts.  This assumes
# some familiarity with Gtk.  ui_start() illustrates four important
# points.
#
# 1. Gtk events do not require require a main window.  It is therefore
# the responsibility of the programmer to create a main window (or
# not) herself.  POE::Kernel's signal_ui_destroy() method attaches a
# UIDESTROY signal to the destruction of a window.  In this case,
# closing the main window signals the program to shut down.
#
# 2. Widgets we need to work with later, such as the counter display,
# must be stored somewhere.  The heap is a convenient place for them.
#
# 3. Gtk widgets expect callbacks in the form of coderefs.  The
# session's postback() method provides coderefs that post events when
# called.  The Button created in ui_start() fires an "ev_clear" event
# when it is pressed.
#
# 4. POE::Kernel methods such as yield(), post(), delay(), signal(),
# and select() (among others) work the same as they would without Gtk.
# This feature makes it possible to write back end sessions that
# support multiple GUIs with a single code base.
sub ui_start {
  my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
  $heap->{main_window} = Gtk2::Window->new("toplevel");
  $kernel->signal_ui_destroy($heap->{main_window});
  my $box = Gtk2::VBox->new(0, 0);
  $heap->{main_window}->add($box);
  my $label = Gtk2::Label->new("Counter");
  $box->pack_start($label, 1, 1, 0);
  $heap->{counter}       = 0;
  $heap->{counter_label} = Gtk2::Label->new($heap->{counter});
  $box->pack_start($heap->{counter_label}, 1, 1, 0);
  my $button = Gtk2::Button->new("Clear");
  $button->signal_connect("clicked", $session->postback("ev_clear"));
  $box->pack_start($button, 1, 1, 0);
  $heap->{main_window}->show_all();
  $kernel->yield("ev_count");
}

# Handle the "ev_count" event by increasing a counter and displaying
# its new value.
sub ui_count {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  $heap->{counter_label}->set_text(++$_[HEAP]->{counter});
  $kernel->delay("ev_count" => 1);
}

# Handle the "ev_clear" event by clearing and redisplaying the
# counter.
sub ui_clear {
  $_[HEAP]->{counter} = 0;
}
