package main;
$VERSION = '0.17';
use Net::Shared::Local;
use Net::Shared::Remote;
use Net::Shared::Handler;

"JAPH";

=head1 NAME

Net::Shared - Shared variables across processes that are either local or remote.

=head1 ABSTRACT

Share data across local and remote processes.

=head1 SYNOPSIS


use Net::Shared;

my $listen         = new Net::Shared::Handler;

my $new_shared     = new Net::Shared::Local(name=>"new_shared", accept=>['127.0.0.1','164.107.70.126']);

my $remote_shared  = new Net::Shared::Remote (name=>"remote_shared", ref=>"new_shared", port=>$new_shared->port, address=>'127.0.0.1');

$listen->add(\$new_shared, \$remote_shared);

$listen->store($new_shared, "One ");

print $listen->retrieve($new_shared);

$listen->store($remote_shared, [qw(and two.)]);

print $listen->retrieve($remote_shared);

$listen->destroy_all;


=head1 DESCRIPTION

C<Net::Shared> gives the ability to share variables across processes both local and remote.
C<Net::Shared::Local> and C<Net::Shared::Remote> objects are created and interfaced with a
C<Net::Shared::Handler> object.  Please see the documentation of the object types below and
also see the examples for more info.

=head2 Net::Shared

Net::Shared itself is just a binding module.  Using it will bring in Net::Shared::Local,
Net::Shared::Remote, and Net::Shared::Handler.

=head2 Net::Shared::Local

C<Net::Shared::Local> is the class that is used to store the data.  Interfacing directly
with C<Net::Shared::Local> objects will almost never need to be done; C<Net::Shared::Handler>'s.
interface should be sufficient.  However, C<Net::Shared::Local> does provide 2 useful methods:
lock and port.  Lock functions like a file lock, and port returns the port number that the object
is listening on.  See the methods section below for more details.  The constructor to C<Net::Shared::Local>
takes 1 argument: a hash.  The hash can be configured to provide a number of
options:

=over 3

=item C<name>

The name that you will use to refer to the variable; it is the only
required option.  It can be anything; it does not have to be the same as the
variable itself.  However, note that if C<Net::Shared::Remote> is going to be used on
another process, it will have to know the C<name> of the shared variable to access it.

=item C<access>

C<access> is an optional field used to designate which addresses to allow
access to the variable.  C<access> requires a reference to an array containing
the addresses to allow.  C<access> will default to localhost if it is not defined.

=item C<port>

Specify which port to listen from; however, its probably best to let the OS pick
on unless C<Net::Shared::Remote> will be used.

=item C<response>

The signal sent to the object that means "send back stored data."  Default
is '\bl\b'.

=item C<debug>

Set to a true value to turn on debuging for the object, which makes it
spew out all sorts of possibly useful info.  Warning: VERY verbose.

=back

As stated earlier, there are also 2 methods that can be called: port and
lock.

=over 3

=item C<port()>

Returns the port number that the Net::Shared::Local object is listening on.

=item C<lock()>

Works like a file lock; 0=not locked; 1=temp lock used during storage,
and 2=complete lock.

=back

=head2 Net::Shared::Remote

C<Net::Shared::Remote> is an alias to accessing data stored by
Shared::Local objects on remote machines.  C<Net::Shared::Remote> also takes
a hash as an argument, similarily to C<Net::Shared::Local>.  However,
C<Net::Shared::Remote> can take many more elements, and all of which are
required (except debug and response).

=over 3

=item C<name>

The name that you will be using to reference this object.

=item C<ref>

Ref will be the name of the Net::Shared::Local object on the machine that
you are accessing.  You MUST correctly specify ref (think of it as
a "password") or you will be unable to access the data.

=item C<address>

The address of the machine where the data that you want to access is
located.

=item C<port>

The port number where the data is stored on the machine which you are
accessing

=item C<response>

The signal sent to the object that means "send back stored data."  Default
is '\bl\b'.  Needs to be the same as whatever the associated C<Net::Shared::Local>
uses.

=item C<debug>

Set to a true value to turn on debuging for the object, which makes it
spew out all sorts of possibly useful info.  Warning: VERY verbose.

=back

There are no methods that you can access with C<Net::Shared::Remote>.

=head2 Net::Shared::Handler

C<Net::Shared::Handler> is the object used to interface with C<Net::Shared::Local>
and C<Net::Shared::Remote> objects.  You can think of C<Net::Shared::Handler> as
the class that actually all of the work: storing the data, retrieving the data, and
managing the objects.  See method descriptions below for more info on methods.  New
accepts 1 argument, and when set to a true value debugging is turned on (only for the Handler
object, however).  Methods:

=over 3

=item C<add(@list)>

Adds a list of C<Net::Shared::Local> / C<Net::Shared::Remote> objects so that they
can be "managed."  Nothing (storing/retrieving/etc) can be done with the
objects until they have been C<add>ed, so don't forget to do it!

=item C<remove(@list)>

C<Remove> effectively kills any objects in C<@list> and all data in them, as
well as remove them from the management scheme.

=item C<store($object, $data)>

Stores the data in C<$object>, whether it be a C<Net::Shared::Local> object or
C<Net::Shared::Remote> object.  Note that storing data in a remote object is actually
just storing in the associated local object.  Returns the number of bytes sent.

=item C<retrieve($object)>

Grabs the data out of C<$object>, and returns it value, in whatever form it was when
stored.  That means if a hash is stored, a hash is returned, so remember to access
C<retrieve> in whatever context the data is expected in.

=item C<destroy_all()>

Standard janitorial method.  Call it at the end of every program in
which C<Net::Shared> Net::shared is used.

=back

=head1 CAVEATS

As of right now, there is no default encryption on the data, so if it is needed,
it will have to be used manually.  That isn't to say the data is unprotected; there
is address and name checking on each end of the transfer.  However, during transmission
the data might as well be in cleartext if a cracker knows it is sent via C<Net::Shared>.

Data is stored in memory, so one should be careful about storing large structures.  Subclassing
C<Net::Shared::Local> and redefining the private methods C<store_data> and C<get_data> to write and
retrieve from file rather than memory might be a good idea if large amounts of data needs to be stored.

=head1 TODO

=over 3

=item Testing

This module needs LOTS of testing on many different platforms.  Please email the author if any bugs are found.

=item Encryption

It would be nice for the user to be able to pass a subroutine defining an
encryption scheme to use, or even to use C<Crypt::RC5> to automatically
encrypt the data if a flag is turned on.

=item Tied Interface

Because tied interfaces are easy to use...

=back

=head1 AUTHOR

Joseph F. Ryan, ryan.311@osu.edu

=head1 COPYRIGHT

Copyright (C) 2002 Joseph F. Ryan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut