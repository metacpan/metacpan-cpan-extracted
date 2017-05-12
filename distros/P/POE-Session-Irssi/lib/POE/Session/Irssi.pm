package POE::Session::Irssi;
use strict;
use warnings;

use POE;
use base qw(POE::Session);

use Sub::Uplevel;
use Carp;
use Irssi;

sub import {
   my ($class) = @_;
   my $package = caller();

   {
      no strict 'refs';
      *{ $package . '::UNLOAD' } = sub {
	    $POE::Kernel::poe_kernel->signal (
	       $POE::Kernel::poe_kernel, 'unload', $package
	    );
	 };
   }
}

#TODO - this should be in POE::Session
sub SE_DATA () { 3 }

use vars qw($VERSION);
$VERSION = '0.50';

# local var we needn't worry about __PACKAGE__ being interpreted as
# a string literal
my $pkg = __PACKAGE__;

=head1 NAME

POE::Session::Irssi - emit POE events for Irssi signals

=head1 SYNOPSIS

  use Irssi;
  use Glib;
  use POE qw(Loop::Glib);
  use POE::Session::Irssi;

  %IRSSI = ( ... fill in the usual stuff for scripts here ... );

  POE::Session::Irssi->create (
      irssi_commands => {
	  hello => sub {
	    my $args = $_[ARG1];
	    my ($data, $server, $witem) = @$args;

	    $server->command("MSG $witem->{name} Hello $data!");
	  },
	},
      irssi_signals => {
	  "message join" => sub {
	    my $args = $_[ARG1];
	    my ($server, $channel, $nick, $address) = @$args;
	    my $me = $server->{nick};

	    if ($nick eq $me) {
	      $server->command("MSG $channel Hello World!");
	    } else {
	      $server->command("MSG $channel Hi there, $nick");
	    }
	  },
	},
      # Other create() args here..
  );

=head1 DESCRIPTION

This L<POE::Session> subclass helps you integrate POE and Irssi scripting.
It connects the signals and commands handlers you define as L<POE> events
with the L<Irssi> machinery. It also tries to clean up as much as possible
when the script gets unloaded, by removing all the alarms your session
has running.

It does this cleaning up by installing an UNLOAD handler that will send an
unload signal. See SIGNALS below for more information.

=head1 CONSTRUCTOR

=head2 create (%args)

Apart from the normal arguments L<POE::Session> create() supports, there
are two more arguments.

=over 2

=item *

irssi_commands

=over 4

  irssi_commands => {
      command_name => \&handler_sub,
  }

=back

As you can see in the example above, this expects a hashref, with
the keys holding the /command you use in Irssi, and the values being
references to the handler function. Because L<POE::Session::Irssi>
creates a postback behind the scenes for each command, your handler
sub will get two arguments in ARG0 and ARG1. These are the normal
postback lists, and the arguments you would normally receive in
an L<Irssi> handler are in the list in ARG1.

Currently, only this inline_state like syntax is supported. Allowing
for object/package states is on the TODO list.

=item *

irssi_signals

=over 4

  irssi_signals => {
      "signal name" => \&handler_sub,
  }

=back

This is much the same as for the irssi_commands. One thing to remember
is that lots of L<Irssi> signals have spaces in their names, so don't
forget to put them inside quotes.

=back

=cut

# subclassing POE::Session methods to work our evil^Wmagic

# here we stick our custom parameters into the newly created $self

sub instantiate {
   my ($class, $params) = @_;

   my $package = caller(1);
   my $self = $class->SUPER::instantiate;

   croak "expecting a hashref" unless (ref($params) eq 'HASH');

   my $irssi_signals = delete $params->{'irssi_signals'};
   if (ref($irssi_signals) eq 'HASH') {
      my %name_map = ();
      #treat as inline states
      $params->{inline_states} = {} unless defined $params->{inline_states};
      while (my ($signal, $handler) = each %$irssi_signals) {
	 my $poe_name = "_irssi_signal_$signal";
	 $poe_name =~ s/ /_/g;
	 $name_map{$signal} = $poe_name;
	 $params->{inline_states}->{$poe_name} = $handler;
      }
      $self->[SE_DATA]->{$pkg}->{"signal_name_map"} = \%name_map;
   }

   my $irssi_commands = delete $params->{'irssi_commands'};
   if (ref($irssi_commands) eq 'HASH') {
      my %name_map = ();
      #treat as inline states
      $params->{inline_states} = {} unless defined $params->{inline_states};
      while (my ($command, $handler) = each %$irssi_commands) {
	 my $poe_name = "_irssi_command_$command";
	 $name_map{$command} = $poe_name;
	 $params->{inline_states}->{$poe_name} = $handler;
      }
      use Data::Dumper;
      #print Dumper \%name_map;
      $self->[SE_DATA]->{$pkg}->{"command_name_map"} = \%name_map;
   }
   $params->{inline_states}->{_irssi_script_unload} = sub {
      my ($kernel, $forme) = @_[KERNEL, ARG1];

      return unless ($forme eq $package);
      # try to clean up so that we get reaped by the kernel
      $kernel->alarm_remove_all;
      $kernel->sig('unload');
      $kernel->sig_handled();
   };

   return $self;
}

# Irssi wants you to call Irssi::signal_add and Irssi::command_bind
# from the Irssi::Script::$name package it creates for your script,
# so it can clean up. This is where we trick it into thinking we're
# doing that.

sub _connect_stuff {
   my ($kernel, $session) = @_[KERNEL, SESSION];

   my $lvl = 1;
   $lvl++ while (caller($lvl - 1) !~ /^Irssi::Script::/);

   my $name_map = $session->[SE_DATA]->{$pkg}->{signal_name_map};
   while (my ($irssi_name, $poe_name) = each %$name_map) {
      my $postback = $session->postback ($poe_name);
      uplevel $lvl, \&Irssi::signal_add, $irssi_name, $postback;
   }
   $name_map = $session->[SE_DATA]->{$pkg}->{command_name_map};
   while (my ($irssi_name, $poe_name) = each %$name_map) {
      my $postback = $session->postback ($poe_name);
      uplevel $lvl, \&Irssi::command_bind, $irssi_name, $postback;
   }
   $kernel->sig(unload => '_irssi_script_unload');
}

# and here we use those to set up our _start
sub try_alloc {
   my ($self, @start_args) = @_;

   my $start_state =
	       $self->[POE::Session::SE_STATES]->{+POE::Session::EN_START};

   my $real_start_state;

   # call any _start the user defined.
   if (defined $start_state) {
      $real_start_state = sub {
	 _connect_stuff (@_);

#	 if (ref ($start_state) ne 'CODE') {
#	    $_[OBJECT] = $object;
#	 }
	 if (ref($start_state) eq 'CODE') {
	 	return &$start_state (@_);
	 } else {
		my ($clobj, $state) = @$start_state;
		shift @_;
		return $clobj->$state (@_);
	 }
      };
   } else {
      $real_start_state = \&_connect_stuff;
   }
   $self->[POE::Session::SE_STATES]->{+POE::Session::EN_START} = $real_start_state;

   return $self->SUPER::try_alloc (@start_args);
}

=head1 SIGNALS

POE allows you to define your own signals, which are handled the same as
system signals. See L<POE::Kernel> for more information.
L<POE::Session::Irssi> defines one such signal:

=head2 unload $package

This signal is sent when irssi tries to unload a script. ARG1 contains the
package name of the script that is being unloaded. L<POE::Session::Irssi>
also creates a handler for this signal that does its best to clean up for
the session by removing any aliases set and removing the signal handler

=head1 NOTES

Since you don't need to call POE::Kernel->run() in Irssi scripts (because
the L<Glib> mainloop is already running), it is no problem at all to
have more than one Irssi script contain a L<POE::Session>. They will
all use the same L<POE::Kernel> and L<POE::Loop>.

=head1 TODO

=over 2

=item *

Allow object/package states

=item *

Maybe put a list of session aliases in an Irssi setting somewhere
This would allow discovery of what other sessions we can talk to.

=back

=head1 AUTHOR

Martijn van Beers  <martijn@eekeek.org>

=head1 LICENSE gpl

This module is Copyright 2006-2008 Martijn van Beers. It is free
software; you may reproduce and/or modify it under the terms of
the GPL version 2.0 or higher. See the file LICENSE in the source
tarball for more information

=cut

1;
