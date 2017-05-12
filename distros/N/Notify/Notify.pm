package Notify;

require 5.00503;
use strict;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
our $VERSION = '0.1';

# This module serves no useful purpose at this time other than as a
# placeholder for documentation

1;

__END__

=head1 NAME

Notify - Framework for asynchronously, remotely notifying users.

=head1 DESCRIPTION

The Notify package aims to simplify applications that need
to be able to communicate remotely with users in a reliable fashion
over various kinds of medium, such as via Email or pager. The
package provides a definition for notification objects, transport
objects for sending and receiving notifications, and a notification
pool manager for managing the creation, update, and resolution of
notification transactions.

This package manages transport and the underlying transaction
mechanisms for communication. It does not, however, dictate the
notification protocol, which is left for application implementation.

=head1 SYNOPSIS

See below.

=head1 REQUIRES

  Tie::Persistent
  Mail::Box
  Mail::Sender

=head1 INTRODUCTION

If you are reading this document, then you have probably installed
this module already :) If not, try the time honoured:

    perl -MCPAN -e'install Notify'

The package is composed of the following modules:

  Notify::Notice

      A simple object defining notification attributes. It provides
      a layer of abstraction for operations on notification data
      structures. The object has a loose structure and is meant
      to be easily extensible in the future.

  Notify::NoticePool

      A notification management object. Allows for the creation,
      updating, and deletion of notifications. All notifications
      added into the pool are persistent and maintain history
      until they are resolved. An asynchronous method is provided
      to advance notification transactions as the application
      requires.

      This module also defines the the two methods required by
      a transport object: the send and receive methods. See the
      POD for more detail.

  Notify::Email

      Implements a transport via Email notification. Notifications
      are sent with the app name and notification ID in the
      subject header. Notifications are also extracted, processed,
      and removed automatically from the monitored mail box by
      the transport object.

The individual modules provide more information in their
respective POD documentation (e.g., perldoc
Notify::NoticePool), so give them a look.

=head1 CREATING A NEW TRANSPORT MODULE

The transport module interface is defined in the POD documentation
for Notify::NoticePool. Transport modules are
registered during the instantiation of the NoticePool object by
instatiating a transport object and passing it in as a field
in the 'transport' key of the NoticePool constructor, e.g:

    'email' => new Notify::Email ({ ... });

If you're interested in seeing support for another transport
object, or adding your own, please contact me (see author
information below). Please note that this interface is
subject to change as the package develops.

=head1 GETTING STARTED

The Notify::NoticePool is the central object in the package and
its POD documentation describes how to integrate the Notify package
into an application. Check it out with a 'perldoc
Notify::NoticePool'.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2001

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

perl (1), Notify::NoticePool, Notify::Notice, Notify::Email

=cut
