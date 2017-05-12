package Reuters::SSL;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	
);
@EXPORT = qw(sslInit sslSnkMount sslSnkOpen sslRegisterCallBack sslDispatchEvent
	sslGetProperty sslGetErrorText sslSnkClose sslDismount sslPostEvent
	sslErrorLog);

$VERSION = '0.52';

bootstrap Reuters::SSL $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Reuters::SSL - Perl extension for Reuters SSL Source Sink Library

=head1 SYNOPSIS

  use Reuters::SSL;

  $retval = sslInit();
  $channel = sslSnkMount(username);
  $retval = sslSnkOpen(Channel, Service, Item [, RequestType] );
  $retval = sslRegisterCallback(Channel, EventType, refToCallbackFunction);
  $retval = sslDispatchEvent(Channel, MaxEvents);
  $retval = sslSnkClose(Channel, Service, Item);
  $retval = sslDismount(Channel);
  ($retval,$fd) = sslGetPropery(Channel,1);
  $ErrorText = sslGetErrorText();
  $retval = sslPostEvent(Channel, EventType, InfoHash);
  $retval = sslErrorLog(FileName, maxFileSize);

  sub callback()
  {
    my $channel = shift;
    my $event = shift;
    my $refHash = shift;
    my %EventHash = \${refHash};
  }


=head1 DESCRIPTION

Reuters::SSL ist the Perl Extension to the Reuters
Source Sink Library, THE Reuters API to access
realtime data from a Reuters Triarch.
The Extension itself is first of all a simple
wrapper to the Library - functions itself, but
furthermore it gives back the data not
with the C-like Pointers to any structure
rather than in a more perl-like hash.

What a comfort!

But you need a full installation of the
Reuters SSL-API which can be bought directly
at Reuters. Please contact your Reuters
representative if you are in doubt.

WARNING:
This software is not supported by Reuters
nor is it developed by Reuters and in any
case Reuters can be made responsible for any
damages or misfunction of this software.

If you would like to learn more about the Reuters
SSL API look in the manuals of Reuters. They are
very good written an can be well understood if you
know what you want to do.
In such terms the Extension is mostly self-explaning
because the functions are the same. But I include
a brief description of how it works:

Initializing:
Before any Realtime-Data can be received with the
library one call to sslInit has to be made. This could
also have been implemented withing the autoloader
for the extension, but I found it more handy to
do it myself when I want to initialize the C-Library.

Mounting:
After initializing the library you can do a sink
mount onto the the triarch. If the username
is left blank it takes the username of the currently
logged in user. The return value should by a number
greater or equal to zero which indicates that
the mount was successfull and the returnvalue
is the channel which is the key value to identifie
a connection to the triarch. The connection is done
to the distributor given in your /var/triarch/ipcroute
file.

SinkOpen:
With the connection to the triarch it is
possible to Open an Item (RIC). But to receive
any data you have to register a callback for
the data you want to receive and call 
sslDispatchEvent. Within the call to
dispatchEvent the callback function is called
as many as events are outstanding to be delivered
to the client. If you have no idea how this
works see the test.pl. It's quite self
explaning.

since 0.52:
You can pass an additional parameter to set
the Request_Type to:
SSL_RT_NORMAL ( the default - value )
SSL_RT_SNAPSHOT ( Only 1 Image is received 
	and the item is closed by the lib )
SSL_RT_HOST ( like normal, but the source is 
	instructed to retrieve the item from 
	the remote host. UNTESTED!! )

SinkClose:
Once you have decided not to receive any
further updates for a given Item you
close the item on the distributor.

Dismount:
This closes all open items and closes the
connection to the distributor. The channel
will be invalidated and can't be used to
further Sinkopens. If you would like to
Open again you first have to Mount to the
distributor.

GetProperty:
This is a quite not very good implementation.
It can only return the associated file
descriptior to the given channel. Therefore
only the Property-Option can only be 1.
Any try to retrieve anything else would
lead to unknmown results including the
crash of the whole machine.

PostEvent:
This function is used to contribute
data to the triarch network. Normally
this service is not the IDN_SELECTFEED
rather than called something like
DCS or DCS_MARKETLINK or MLCS.
The third parameter (InfoHash) must
contain the keys for:
ServiceName
InsertName
Data
DataLength

But be careful. Perl does not recognize
right the length of the Datastring with
the length() function because of the
special characters included in this string.
Count yourself!



=head1 AUTHOR

C. Barkey, christian.barkey@hvb.lu

=head1 SEE ALSO

perl(1).

=head1 TODO

Full implementation of the sslGetProperty.

Actually there is only the Sink - Methods
implemented and the PostEvent for
contributing data to the triarch.

Comfortable Functions for bulding up
the data - string for contributing
and receiving data. One ugly could be
found in the test.pl but it is really
not very useful.

If you feel that there is still something
else missing, don't hesitate to contact
me and I will see what I can do for you.


WARNING
The Code is actually in alpha release and
not yet sophisticated tested and verified.
Furthermore there are actually no type-checkes
to ensure proper call tp the XS-functions
so be carefull and read the manuals and
this documentation.

=head1 COPYRIGHT

This software is published under the terms
of the GPL.

=head1 CHANGES

0.02 Added parameter checks to xs-functions
0.50 Found some memory leaks but was unable to fix them
0.51 Fixed forgotten returnvalue of callback
     and added some static casts to avoid compiler warnings
     (Thanks to Waseem Wali)
0.52 added sslErrorLog - function
     to log into defined files and not only
     the default files 
     added optional Parameter to
     sslSnkOpen to change the 
     RequestType to Normal/Snapshot/Host
     worked on test.pl to make the
     output more readable
     (Thanks to Waseem Wali for proposals)

=cut
