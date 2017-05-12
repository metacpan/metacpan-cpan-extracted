#!/usr/bin/perl

# http://poe.perl.org/?POE_Cookbook/Gtk_Interfaces
#
# This sample program creates a very simple Gtk counter.  Its
# interface consists of three widgets: A label, a rapidly increasing
# counter, and a button to reset that counter.

# the 1 - 4 here corresponds to the points in the cookbook entry without
# glade

# 4. Because with POE::Session::GladeXML2, you create the gui through glade
# instead of code, and because it expects all the gtk signal handlers to
# be in a seperate package, it becomes even easier to seperate the GUI
# specific code from the non-gui-dependant code.
package Foo;
use warnings;
use strict;

# POE::Loop::Glib doesn't initialize Gtk2 (for obvious reasons), so we
# do it here
use Gtk2 -init;
use POE;
use POE::Session::GladeXML2;

sub new {
  my ($class) = @_;

  my $self = bless {}, $class;

  my $session = POE::Session::GladeXML2->create (
    glade_object => $self,
    glade_file => 'cookbook.glade',
# 1. You can use the glade_mainwin parameter to create() to tell which
# widget should be considered the main window.
    glade_mainwin => 'window1',
    inline_states =>
      { _start => \&ui_start,
        ev_count => \&ui_count,
      }
  );
  return $self;
}


sub ui_start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    $heap->{counter} = 0;
    $kernel->yield("ev_count");
}

# Handle the "ev_count" event by increasing a counter and displaying
# its new value.

sub ui_count {
    my ( $session, $kernel, $heap ) = @_[ SESSION, KERNEL, HEAP ];
    
# 2. When using Gtk2::GladeXML, you can get any widget by name. Thus
# there is no more need to store them yourself.

    my $label = $session->gladexml->get_widget ('counter_label');
    $label->set_text( ++$heap->{counter} );
    $kernel->yield("ev_count");
}

# 3. Instead of having to manually connect gtk signals with poe event
# handlers, POE::Session::GladeXML2 automatically connects the handler
# name you set in glade with the corresponding method in the object you
# pass as glade_object.

sub ui_clear {
    $_[HEAP]->{counter} = 0;
}

package main;

use POE;
# Run the program until it is exited.

my $foo = Foo->new;
$poe_kernel->run();
exit 0;

