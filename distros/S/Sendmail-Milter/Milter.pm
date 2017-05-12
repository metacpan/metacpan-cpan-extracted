#
# Copyright (c) 2000-2001 Charles Ying. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as sendmail itself.
#

package Sendmail::Milter;

use 5.006;

use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sendmail::Milter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	SMFIF_ADDHDRS
	SMFIF_ADDRCPT
	SMFIF_CHGBODY
	SMFIF_CHGHDRS
	SMFIF_DELRCPT
	SMFIF_MODBODY
	SMFIS_ACCEPT
	SMFIS_CONTINUE
	SMFIS_DISCARD
	SMFIS_REJECT
	SMFIS_TEMPFAIL
	SMFI_CURR_ACTS
	SMFI_V1_ACTS
	SMFI_V2_ACTS
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	SMFIF_ADDHDRS
	SMFIF_ADDRCPT
	SMFIF_CHGBODY
	SMFIF_CHGHDRS
	SMFIF_DELRCPT
	SMFIF_MODBODY
	SMFIS_ACCEPT
	SMFIS_CONTINUE
	SMFIS_DISCARD
	SMFIS_REJECT
	SMFIS_TEMPFAIL
	SMFI_CURR_ACTS
	SMFI_V1_ACTS
	SMFI_V2_ACTS
);

our $VERSION = '0.18';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Sendmail::Milter macro $constname";
	}
    }
    {
	no strict 'refs';

	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

bootstrap Sendmail::Milter $VERSION;

# Preloaded methods go here.

our %DEFAULT_CALLBACKS =
(
	'connect' =>	'connect_callback',
	'helo' =>	'helo_callback',
	'envfrom' =>	'envfrom_callback',
	'envrcpt' =>	'envrcpt_callback',
	'header' =>	'header_callback',
	'eoh' =>	'eoh_callback',
	'body' =>	'body_callback',
	'eom' =>	'eom_callback',
	'abort' =>	'abort_callback',
	'close' =>	'close_callback',
);


sub auto_setconn
{
	my $name = shift;
	my $cf_filename = shift || undef;

	my $conn_info = Sendmail::Milter::auto_getconn($name, $cf_filename);

	if ($conn_info)
	{
		Sendmail::Milter::setconn($conn_info);
		return 1;
	}

	return 0;
}

sub auto_getconn
{
	my $name = shift;
	my $cf_filename = shift || '/etc/mail/sendmail.cf';
	my $raw_file;

	my $current_name;
	my $conn_info;

	open(CF_FILE, $cf_filename) || die "Can't open '$cf_filename' for reading: $!";

	$raw_file = join('', <CF_FILE>);
	$raw_file =~ s/\n[ \t]/ /g;

	close(CF_FILE);

	foreach my $line (split(/\n/, $raw_file))
	{
		chomp $line;

		# Just ignore rest of line in case it's F=T, T=blah...
		# Or just T=blah...
	
		if ($line =~ /^X(.+),\s*S\=(.+),\s*[FT]\=(.)/)
		{
			$current_name = $1;
			$conn_info = $2;

			if ($current_name eq $name)
			{
				return $conn_info;
			}
		}
		elsif ($line =~ /^X(.+),\s*S\=(.+)/)
		{
			$current_name = $1;
			$conn_info = $2;

			if ($current_name eq $name)
			{
				return $conn_info;
			}
		}
	}

	return undef;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Sendmail::Milter - Interface to sendmail's Mail Filter API

=head1 SYNOPSIS

  use Sendmail::Milter;

  my %my_milter_callbacks =
  (
	'connect' =>	\&my_connect_callback,
	'helo' =>	\&my_helo_callback,
	'envfrom' =>	\&my_envfrom_callback,
	'envrcpt' =>	\&my_envrcpt_callback,
	'header' =>	\&my_header_callback,
	'eoh' =>	\&my_eoh_callback,
	'body' =>	\&my_body_callback,
	'eom' =>	\&my_eom_callback,
	'abort' =>	\&my_abort_callback,
	'close' =>	\&my_close_callback,
  );

  sub my_connect_callback;
  sub my_helo_callback;
  sub my_envfrom_callback;
  sub my_envrcpt_callback;
  sub my_header_callback;
  sub my_eoh_callback;
  sub my_body_callback;
  sub my_eom_callback;
  sub my_abort_callback;
  sub my_close_callback;


  BEGIN:
  {
	# Get myfilter's connection information
	# from /etc/mail/sendmail.cf

	Sendmail::Milter::auto_setconn("myfilter");
	Sendmail::Milter::register("myfilter",
		\%my_milter_callbacks, SMFI_CURR_ACTS);

	Sendmail::Milter::main();

	# Never reaches here, callbacks are called from Milter.
  }

=head1 DESCRIPTION

B<Sendmail::Milter> is a Perl extension to sendmail's Mail Filter API (Milter).

B<Note:> You need to have a Perl 5.6 or later interpreter built with
B<-Dusethreads>.

=head1 FUNCTIONS

Portions of this document come from comments in the B<libmilter/mfapi.h> header
file.

=head2 Main Functions

B<Note:> No functions are exported. You must call these functions explicitly
from the B<Sendmail::Milter> package.

=over 4

=item register NAME, CALLBACKS [, FLAGS]

Registers a mail filter NAME with hash reference CALLBACKS callbacks, and
optional capability flags FLAGS. NAME is the same filter name that you would
pass to B<auto_setconn>. CALLBACKS is a hash reference that can contain any of
the following keys:

  connect
  helo
  envfrom
  envrcpt
  header
  eoh
  body
  eom
  abort
  close

The values for these keys indicate the callback routine that is associated with
each Milter callback. The values must be either function names, code references
or closures.

This function returns nonzero upon success, the undefined value otherwise.

B<%Sendmail::Milter::DEFAULT_CALLBACKS> is a hash with default function names
for all of the Milter callbacks. The default callback function names are:

B<connect_callback>, B<helo_callback>, B<envfrom_callback>,
B<envrcpt_callback>, B<header_callback>, B<eoh_callback>, B<body_callback>,
B<eom_callback>, B<abort_callback>, B<close_callback>.

See the section B<Writing Milter Callbacks> for more information on writing
the callbacks themselves.

For more information on capability flags, see the section B<Capability Flags>
in the B<@EXPORT> section.

=item main [MAX_INTERPRETERS] [, MAX_REQUESTS]

Starts the mail filter. If successful, this function never returns. Instead, it
launches the Milter engine which will call each of the callback routines as
appropriate.

MAX_INTERPRETERS sets the limit on the maximum number of interpreters that
B<Sendmail::Milter> is allowed to create. These interpreters will only be
created as the need arises and are not all created at startup. The default
value is 0. (No maximum limit)

MAX_REQUESTS sets the limit on the maximum number of requests an interpreter
will process before being recycled. The default value is 0. (Don't recycle
interpreters)

This function returns nonzero on success (if a kill was signaled or something),
the undefined value otherwise.

B<Note:> You should have at least registered a callback and set the connection
information string before calling this function.


=item setconn CONNECTION_INFO

Sets the connection information string for the filter. The format of this
string is identical to that found in the Milter documentation. Some examples
are C<local:/var/run/f1.sock>, C<inet6:999@localhost>, C<inet:3333@localhost>.

This function returns nonzero upon success, the undefined value otherwise.


=item auto_setconn NAME [, SENDMAIL_CF_FILENAME]

This function automatically sets the connection information by parsing the
sendmail .cf file for the appropriate X line containing the connection
information for the NAME mail filter and calling B<setconn> if it was
successful. It is provided as a helper function and does not exist in the
current Milter library.

B<Note:> This connection information isn't useful for implementing a Milter
that resides on a machine that is remote to the machine running sendmail. In
those cases, you will want to set the connection information manually with
B<setconn>.

This function returns nonzero upon success, the undefined value otherwise.

SENDMAIL_CF_FILENAME defaults to C</etc/mail/sendmail.cf> if not specified.


=item auto_getconn NAME [, SENDMAIL_CF_FILENAME]

Similar to B<auto_setconn>, this function parses the sendmail .cf file for the
appropriate X line containing the connection information for NAME. It does not,
however, call B<setconn>. It only retrieves the connection information.

This function returns the connection information string for NAME, or undef on
failure.

SENDMAIL_CF_FILENAME defaults to C</etc/mail/sendmail.cf> if not specified.


=item settimeout TIMEOUT

Sets the timeout for reads/writes in the Milter engine.

This function returns nonzero upon success, the undefined value otherwise.


=item setdbg LEVEL

Sets the debug level for the Milter engine.

This function returns nonzero upon success, the undefined value otherwise.


=back



=head2 Writing Milter Callbacks

Writing Milter callbacks is pretty easy when you're doing simple text
processing.

But remember one thing: Each Milter callback could quite possibly run in a
different instance of the Perl interpreter.

B<Sendmail::Milter> launches multiple persistent Perl interpreters to increase
performance (so it doesn't have to startup and shutdown the interpreters
constantly). Thus, you can't rely on setting external package variables, global
variables, or even running other modules which rely on such things. This will
continue to be true while interpreter thread support in Perl is experimental.
For more information, see L<perlfork>. Most of that information applies here.

Remember to return one of the B<SMFIS_*> result codes from the callback
routine. Remember there can be multiple message body chunks. And remember that
only B<eom_callback> is allowed to manipulate the headers, recipients, message
body, etc.

See the B<@EXPORT> section for information on the B<SMFIS_*> result codes.

Here is an example of a B<connect_callback> routine:

  # External modules are OK, but note the caveats above.
  use Socket;	

  sub connect_callback
  {
	my $ctx = shift;	# The Milter context object.
	my $hostname = shift;	# The connection's host name.
	my $sockaddr_in = shift;
	my ($port, $iaddr) = sockaddr_in($sockaddr_in);

	print "Hostname is: " . $hostname . "\n";

	# Cool, a printable IP address.
	print "IP Address is: " . inet_ntoa($iaddr) . "\n";

	return SMFIS_CONTINUE;	# Returning a value is important!
  }

B<Note:> The $ctx Milter context object is not a true Perl object. It's really
a blessed reference to an opaque C structure. Only use the Milter context
functions (described in a later section) with this object.  (Don't touch it,
it's evil.)

=head2 Milter Callback Interfaces

These interfaces closely mirror their Milter callback counterparts, however
there are some differences that take advantage of Perl's syntactic sugar.

B<Note:> Each callback receives a Milter context object as the first
argument. This context object is used in making Milter Context function
calls. See B<Milter Context Functions> for more details.

=over 4

=item B<connect_callback> CTX, HOSTNAME, SOCKADDR_IN

Invoked on each connection. HOSTNAME is the host domain name, as determined by
a reverse lookup on the host address. SOCKADDR_IN is the AF_INET portion of the
host address, as determined by a B<getpeername(2)> syscall on the SMTP
socket. You can use B<Socket::unpack_sockaddr_in()> to unpack it into a port
and IP address.

This callback should return one of the B<SMFIS_*> result codes.


=item B<helo_callback> CTX, HELOHOST

Invoked on SMTP HELO/EHLO command. HELOHOST is the value passed to HELO/EHLO
command, which should be the domain name of the sending host (but is, in
practice, anything the sending host wants to send).

This callback should return one of the B<SMFIS_*> result codes.


=item B<envfrom_callback> CTX, ARG1, ARG2, ..., ARGn

Invoked on envelope from. ARG1, ARG2, ... ARGn are SMTP command arguments. ARG1
is guaranteed to be the sender address. Later arguments are the ESMTP
arguments.

This callback should return one of the B<SMFIS_*> result codes.


=item B<envrcpt_callback> CTX, ARG1, ARG2, ..., ARGn

Invoked on each envelope recipient. ARG1, ARG2, ... ARGn are SMTP command
arguments. ARG1 is guaranteed to be the recipient address. Later arguments are
the ESMTP arguments.

This callback should return one of the B<SMFIS_*> result codes.


=item B<header_callback> CTX, FIELD, VALUE

Invoked on each message header. The content of the header may have folded white
space (that is, multiple lines with following white space) included. FIELD is
the header field name, VALUE is the header field value.

This callback should return one of the B<SMFIS_*> result codes.


=item B<eoh_callback> CTX

Invoked at end of header.

This callback should return one of the B<SMFIS_*> result codes.


=item B<body_callback> CTX, BODY, LEN

Invoked for each body chunk. There may be multiple body chunks passed to the
filter. End-of-lines are represented as received from SMTP (normally
Carriage-Return/Line-Feed). BODY contains the body data, LEN contains the
length of the body data.

This callback should return one of the B<SMFIS_*> result codes.


=item B<eom_callback> CTX

Invoked at end of message. This routine can perform special operations such as
modifying the message header, body, or envelope. See the section on
B<eom_callback> in B<Milter Context Functions>.

This callback should return one of the B<SMFIS_*> result codes.


=item B<abort_callback> CTX

Invoked if message is aborted outside of the control of the filter, for
example, if the SMTP sender issues an RSET command. If B<abort_callback> is
called, B<eom_callback> will not be called and vice versa.

This callback should return one of the B<SMFIS_*> result codes.


=item B<close_callback> CTX

Invoked at end of the connection. This is called on close even if the previous
mail transaction was aborted.

This callback should return one of the B<SMFIS_*> result codes.


=back



=head2 Milter Context Functions

These routines are object methods that are part of the
B<Sendmail::Milter::Context> pseudo-package for use by B<Sendmail::Milter>
callback functions. Any attempts to use them without a properly blessed Milter
context object will fail miserably. Please see restrictions on when these
routines may be called.

B<Context routines available to all Milter callback functions:>

These functions are available to all types of Milter callback functions. It is
worth noting that passing connection-private data by reference is probably more
efficient than passing by value.

=over 4

=item B<$ctx>-E<gt>setpriv DATA

Each B<$ctx> can contain connection-private data (specific to an SMTP
connection). This routine can be used to allocate this private data. Calling
this function with DATA set to the undefined value will clear Milter's pointer
to this private data. You should always do this to decrement the private data's
reference count.

This function returns nonzero upon success, the undefined value otherwise.


=item B<$ctx>-E<gt>getpriv

Each B<$ctx> can contain connection-private data (specific to an SMTP
connection). This routine can be used to retrieve this private data.

This function returns a scalar containing B<$ctx>'s private data.


=item B<$ctx>-E<gt>getsymval SYMNAME

Additional information is passed in to the vendor filter routines using
symbols. Symbols correspond closely to sendmail macros. The symbols defined
depend on the context. SYMNAME is the name of the symbol to access.

This function returns the value of the symbol name SYMNAME. 


=item B<$ctx>-E<gt>setreply RCODE, XCODE, MESSAGE

Set the specific reply code to be used in response to the active command. If
not specified, a generic reply code is used.
RCODE is the three-digit (B<RFC 821>) SMTP reply code to be returned, e.g. C<551>.
XCODE is the extended (B<RFC 2034>) reply code, e.g., C<5.7.6>.
MESSAGE is the text part of the SMTP reply.

This function returns nonzero upon success, the undefined value otherwise.

=back


B<Context routines available only to the eom_callback function:>

The B<eom_callback> Milter callback is called at the end of a message
(essentially, after the final DATA dot). This routine can call some special
routines to modify the envelope, header, or body of the message before the
message is enqueued. These routines must not be called from any vendor routine
other than B<eom_callback>.

=over 4

=item B<$ctx>-E<gt>addheader FIELD, VALUE

Add a header to the message. FIELD is the header field name. VALUE is the
header field value. This header is not passed to other filters. It is not
checked for standards compliance; the mail filter must ensure that no protocols
are violated as a result of adding this header.

This function returns nonzero upon success, the undefined value otherwise.


=item B<$ctx>-E<gt>chgheader FIELD, INDEX, VALUE

Change/delete a header in the message. FIELD is the header field name. INDEX is
the Nth occurence of the header field name. VALUE is the new header field value
(empty for delete header). It is not checked for standards compliance; the mail
filter must ensure that no protocols are violated as a result of adding this
header.

This function returns nonzero upon success, the undefined value otherwise.


=item B<$ctx>-E<gt>addrcpt RCPT

Add a recipient to the envelope. RCPT is the recipient to be added.

This function returns nonzero upon success, the undefined value otherwise.


=item B<$ctx>-E<gt>delrcpt RCPT

Delete a recipient from the envelope. RCPT is the envelope recipient to be
deleted. This should be in exactly the same form passed to B<envrcpt_callback>
or the address may not be deleted.

This function returns nonzero upon success, the undefined value otherwise.


=item B<$ctx>-E<gt>replacebody DATA

Replace the body of the message. DATA is the scalar containing the block of
message body information to insert. This routine may be called multiple times
if the body is longer than convenient to send in one call. End of line should
be represented as Carriage-Return/Line Feed.

This function returns nonzero upon success, the undefined value otherwise.


=back



=head1 @EXPORT

B<Sendmail::Milter> exports the following constants:

=head2 Callback Result Codes

These are the possible result codes that may be returned by the Milter callback
functions. If you do not specify a return value, B<Sendmail::Milter> will send
a default result code of B<SMFIS_CONTINUE> back to Milter.

=over 4

=item SMFIS_CONTINUE

Continue processing message/connection

=item SMFIS_REJECT

Reject the message/connection.  No further routines will be called for this
message (or connection, if returned from a connection-oriented routine).

=item SMFIS_DISCARD

Accept the message, but silently discard the message.  No further routines will
be called for this message.  This is only meaningful from message-oriented
routines.

=item SMFIS_ACCEPT

Accept the message/connection. No further routines will be called for this
message (or connection, if returned from a connection-oriented routine; in this
case, it causes all messages on this connection to be accepted without
filtering).

=item SMFIS_TEMPFAIL

Return a temporary failure, i.e., the corresponding SMTP command will return a
4xx status code.  In some cases this may prevent further routines from being
called on this message or connection, although in other cases (e.g., when
processing an envelope recipient) processing of the message will continue.

=back

=head2 Capability Flags

These are possible capability flags for what a mail filter can do. 
Normally, you should specify each capability explicitly as needed.

=over 4

=item SMFIF_ADDHDRS

Allows a mail filter to add headers.

=item SMFIF_CHGBODY

Allows a mail filter to change the message body.

=item SMFIF_ADDRCPT

Allows a mail filter to add recipients.

=item SMFIF_DELRCPT

Allows a mail filter to delete recipients.

=item SMFIF_CHGHDRS

Allows a mail filter to change headers.

=item SMFIF_MODBODY

Allows a mail filter to change the message body. (Provided only for backwards
compatibility)

=back


=head2 Capability Flag Sets

These provide sets of capability flags that indicate all of the capabilities in
a particular version of Milter. B<SMFI_CURR_ACTS> is set to the capabilities in
the current version of Milter.

=over 4

=item SMFI_CURR_ACTS

Enables the set of capabilities available to mail filters in the current
version of Milter.

=item SMFI_V1_ACTS

Enables the set of capabilities available to mail filters in V1 of Milter.

=item SMFI_V2_ACTS

Enables the set of capabilities available to mail filters in V2 of Milter.

=back


=head1 EXAMPLES

=head2 Appending a line to the message body

  use Sendmail::Milter;

  my %my_milter_callbacks =
  (
	'eoh' =>	\&my_eoh_callback,
	'body' =>	\&my_body_callback,
	'eom' =>	\&my_eom_callback,
	'abort' =>	\&my_abort_callback,
  );

  sub my_eoh_callback
  {
	my $ctx = shift;
	my $body = "";

	$ctx->setpriv(\$body);

	return SMFIS_CONTINUE;
  }

  sub my_body_callback
  {
	my $ctx = shift;
	my $body_chunk = shift;
	my $body_ref = $ctx->getpriv();

	${$body_ref} .= $body_chunk;

	# This is crucial, the reference to the body may have
	# changed.

	$ctx->setpriv($body_ref);

	return SMFIS_CONTINUE;
  }

  sub my_eom_callback
  {
	my $ctx = shift;
	my $body_ref = $ctx->getpriv();

	# Note: This doesn't support messages with MIME data.

	${$body_ref} .= "---> Append me to this message body!\n";

	$ctx->replacebody(${$body_ref});

	$ctx->setpriv(undef);

	return SMFIS_ACCEPT;
  }

  sub my_abort_callback
  {
	my $ctx = shift;

	$ctx->setpriv(undef);

	return SMFIS_CONTINUE;
  }


  # The following code does not necessarily need to be in a
  # BEGIN block. It just looks funny without it. :)

  BEGIN:
  {
	Sendmail::Milter::auto_setconn("myfilter");
	Sendmail::Milter::register("myfilter",
		\%my_milter_callbacks, SMFI_CURR_ACTS);

	Sendmail::Milter::main();

	# Never reaches here, callbacks are called from Milter.
  }


See the B<test.pl> sample test case for more callback examples.

=head1 AUTHOR

Charles Ying, cying@cpan.org.

=head1 COPYRIGHT

Copyright (c) 2000-2001 Charles Ying. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as sendmail itself.

The interpreter pools portion (found in the intpools.c, intpools.h, and test.pl
files) of this code is also available under the same terms as perl itself.

=head1 SEE ALSO

perl(1),  sendmail(8).

=cut
