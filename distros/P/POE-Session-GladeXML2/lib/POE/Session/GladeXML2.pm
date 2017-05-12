package POE::Session::GladeXML2;
use strict;
use warnings;


#TODO - this should be in POE::Session
sub SE_DATA () { 3 }

our $VERSION = '0.40';
use base qw(POE::Session);

# local var so we needn't worry about __PACKAGE__ being interpreted as
# a string literal
my $pkg = __PACKAGE__;

=head1 NAME

POE::Session::GladeXML2 - emit POE events for Gtk2 callbacks

=head1 SYNOPSIS

   package test;

   use POE::Session::GladeXML2;

   # the name of the sub needs to match with the name you entered in
   # the glade signal handler dialog.
   sub on_button1_clicked {
      print STDERR "button clicked\n";
   }

   sub new {
      [... object creation ...]
      my $session = POE::Session::GladeXML2->create (
	  glade_object => $self,
	  glade_file => 'test.glade',
	  glade_args => 'widgetname',
	  [... POE Session params ...]
	);

      return $self;
   }

   Gtk2::GladeXML->init;
   my $foo = test->new;
   $poe_kernel->run();

=head1 DESCRIPTION

A simple helper module that lets you connect callback names from
your .glade file with methods of an object. These methods are called
as POE callback or postback methods. L<POE::Session::GladeXML> automatically
determines whether gtk expects the signal handler to return a value. If
it does, a callback is used, otherwise a postback will be used.

=cut

use Carp;
use Gtk2 -init;
use POE;
use Gtk2::GladeXML;

sub _session_autoconnect_helper {
  my ($handler_name, $gobject, $signal_name, $signal_data,
      $connect_object, $is_after, $session_object, $event_name) = @_;

  # So things like Glade2::Widget can call this with an extra
  # parameter that defines the event name, so you can have
  # more than one event use the same handler. Glade2::Widget
  # uses that to allow more than one widget to exist in the
  # same session
  $event_name = $handler_name unless defined $event_name;

  $poe_kernel->state ($event_name, $session_object, $handler_name);
  my $session = $poe_kernel->get_active_session;
  my $handler;

  my $sig_info = $gobject->signal_query ($signal_name);

  if (!defined $sig_info->{'return_type'}) {
	$handler = $session->postback ($event_name);
  } else {
	$handler = $session->callback ($event_name);
  }

  if ($connect_object) {
    my ($func) = $is_after ? "signal_connect_object_after" : "signal_connect_object";
    $gobject->$func ($signal_name, $connect_object, $handler, $signal_data);
  } else {
    my ($func) = $is_after ? "signal_connect_after" : "signal_connect";
    $gobject->$func ($signal_name, $handler, $signal_data);
  }
}

=head1 CONSTRUCTOR

=head2 create (%args)

creates a POE::Session that connects the callbacks from the glade file
to the corresponding method of the object in the glade_object argument.
The glade_file argument contains the name of the glade file to use. Optional
arguments for Gtk::GladeXML->new are in the glade_args argument. See
C<Gtk2::GladeXML> for more information.

If you are using this to create your main window, you can put the name of
that in a glade_mainwin argument, which will then be used to make POE exit
when this window is closed.

=cut


# subclassing POE::Session methods to work our evil^Wmagic

# here we stick our custom parameters into the newly created $self
sub instantiate {
   my ($class, $params) = @_;

   my $self = $class->SUPER::instantiate;
   croak "expecting a hashref" unless (ref ($params) eq 'HASH');

   my $object = delete $params->{'glade_object'};
   croak $class . " MUST have a glade_object option"
      unless (defined $object);
   my $file = delete $params->{'glade_file'};
   croak $class . " MUST have a glade_file option"
      unless (defined $file);
   my $glade_args = delete $params->{'glade_args'};
   my $glade_mainwin = delete $params->{'glade_mainwin'};

   $self->[SE_DATA]->{$pkg}->{"glade_object"} = $object;
   $self->[SE_DATA]->{$pkg}->{"glade_file"} = $file;
   $self->[SE_DATA]->{$pkg}->{"glade_args"} = $glade_args if (defined $glade_args);
   $self->[SE_DATA]->{$pkg}->{"glade_mainwin"} = $glade_mainwin if (defined $glade_mainwin);

   return $self;
}

# help for try_alloc
sub _prepare_widgets {
   my ($kernel, $session, @args) = @_[KERNEL, SESSION, ARG0..$#_];

   my $object = $session->[SE_DATA]->{$pkg}->{"glade_object"};
   my $file = $session->[SE_DATA]->{$pkg}->{"glade_file"};
   my $glade_args = $session->[SE_DATA]->{$pkg}->{"glade_args"};
   $glade_args = [] unless (defined $glade_args);

   my $t = Gtk2::GladeXML->new ($file, @$glade_args);
   croak "Couldn't create Gtk2::GladeXML" unless (defined $t);

   $session->[SE_DATA]->{$pkg}->{'xml'} = $t;
   $t->signal_autoconnect (\&_session_autoconnect_helper, $object);
   my $mainwin = $session->[SE_DATA]->{$pkg}->{'glade_mainwin'};
   if (defined $mainwin) {
      my $widget = $t->get_widget ($mainwin);
      $kernel->signal_ui_destroy ($widget);
   }
}

# and here we use those to set up our _start
sub try_alloc {
   my ($self, @start_args) = @_;

   my $start_state =
	       $self->[POE::Session::SE_STATES]->{+POE::Session::EN_START};

   my $object = $self->[SE_DATA]->{$pkg}->{"glade_object"};
   my $file = $self->[SE_DATA]->{$pkg}->{"glade_file"};
   my $glade_args = $self->[SE_DATA]->{$pkg}->{"glade_args"};
   $glade_args = [] unless (defined $glade_args);

   my $real_start_state;

   # call any _start the user defined.
   if (defined $start_state) {
      $real_start_state = sub {
	 _prepare_widgets (@_);

	 if (ref ($start_state) ne 'CODE') {
	    $_[OBJECT] = $object;
	 }
	 if (ref($start_state) eq 'CODE') {
	 	return &$start_state (@_);
	 } else {
		my ($clobj, $state) = @$start_state;
		shift @_;
		return $clobj->$state (@_);
	 }
      };
   } else {
      $real_start_state = \&_prepare_widgets;
   }
   $self->[POE::Session::SE_STATES]->{+POE::Session::EN_START} = $real_start_state;

   return $self->SUPER::try_alloc (@start_args);
}

=head1 METHODS

=head2 gladexml ()

Returns the Gtk2::GladeXML object.

=cut

sub gladexml {
  my ($self) = @_;

  return $self->[SE_DATA]->{$pkg}->{'xml'}
}

=head1 SEE ALSO

C<POE::Session> and C<Gtk2::GladeXML>

=head1 AUTHOR

Martijn van Beers  <martijn@cpan.org>

=head1 LICENSE

This module is free software; you may reproduce and/or modify it
under the terms of the GPL license v2.0. See the file LICENSE in
the source tarball for more information

=head2 ACKNOWLEDGEMENTS

This module wouldn't be half as good without the invaluable advice
of Rocco Caputo and Scott Arrington.

=cut

1;
