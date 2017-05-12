
package Net::SSLeay::OO;

use Net::SSLeay;
use Net::SSLeay::OO::Functions;
use Net::SSLeay::OO::Error;
use Net::SSLeay::OO::Context;
use Net::SSLeay::OO::SSL;

our $VERSION = "0.02";

1;

__END__

=head1 NAME

Net::SSLeay::OO - OO Calling Method for Net::SSLeay

=head1 SYNOPSIS

 use Net::SSLeay::OO;

 use Net::SSLeay::OO::Constants qw(OP_ALL OP_NO_TLSv2);

 my $ctx = Net::SSLeay::OO::Context->new;
 $ctx->set_options(OP_ALL & OP_NO_TLSv2);
 $ctx->load_verify_locations("", "/etc/ssl/certs");

 # get a socket/stream somehow
 my $socket = IO::Socket::INET->new(...);

 # create a new SSL object, and attach it to the socket
 my $ssl = Net::SSLeay::OO::SSL->new(ctx => $ctx);
 $ssl->set_fd($socket);

 # initiate the SSL connection
 $ssl->connect;

 # exchange data ... be sure to read the man page
 my $wrote = $ssl->write($data, $size);
 my $bytes_read = $ssl->read(\$buf, $size);

 # close...
 $ssl->shutdown;
 $socket->shutdown(1);

=head1 DESCRIPTION

This set of modules adds an OO calling convention to the
L<Net::SSLeay> module.  It steers away from overly abstracting things,
or adding new behaviour, instead just making the existing
functionality easier to use.

What does this approach win you over L<Net::SSLeay>?

=over

=item B<Object Orientation>

For a start, you get a blessed object rather than an integer to work
with, so you know what you are dealing with.  All of the functions
which were callable with C<Net::SSLeay::foo($ssl, @args)> will then be
callable as plain C<$ssl-E<gt>foo(@args)>.

=item B<Namespaces>

The OpenSSL functions use a C-style namespace convention, where
functions are prefixed by the type of the object that they operate on.
OpenSSL has several types of objects, such as a "Context" (this is a
bit like a bunch of pre-defined connection settings), and various
classes relating to X509, sessions, etc.

This module splits up the functions which L<Net::SSLeay> binds into
Perl based on the naming convention, then sets up wrappers for them so
that you can just call methods on objects.

=item B<Exceptions>

If an error is raised by the OpenSSL library, an exception is
immediately raised (trappable via C<eval>) which pretty-prints into
something presented a little less cryptic than OpenSSL's
C<:>-delimited error string format.

=item B<fewer segfaults>

This is currently more of a promise than a reality; but eventually
each of the access methods for the various objects will be able to
know their lifetime in a robust fashion, so you should get less
segfaults.  Eg, some SSL functions don't return object references
which are guaranteed to last very long, so if you wait too long before
getting properties from them you will get a segfault.

=back

On the flip side, what does this approach win you over other simpler
APIs such as L<IO::Socket::SSL>?  Well, I guess it comes down to "Make
things as simple as possible, but no simpler".

Most SSL socket libraries tend to try to hide complexity from you, but
there really are things that you should consider; such as, shouldn't
you be validating the other end of your SSL connection has a valid
certificate?  Which SSL versions do you wish to allow?

L<IO::Socket::SSL> lets you specify a lot of this stuff, but it's not
a very earnest implementation; it's just treated as a few extra
options passed to the constructor, a bit of magic at socket setup
time, and then hope that this will be enough.  The support for
verifying client certificates didn't even work when I tested it.

On the other hand, using the OpenSSL API fully means you are taken
through the stages of setup piece by piece.  You can easily do things
like check that your SSL configuration (eg server certificate) is
valid I<before> you start daemonize or start accepting real sockets.

I'll try to keep the documentation as complete as possible - there's
nothing more annoying than thin wrapper libraries which don't help
much people trying to use them.  But in general, most functions
available in the OpenSSL manual will be available.

=head1 DISTRIBUTION OVERVIEW / PACKAGES

This is a brief overview of the packages in this module, so that you
know where to start.

=over

=item L<Net::SSLeay::OO::Context> (C: C<SSL_CTX*>)

The context object represents an individual configuration of the
OpenSSL library.  Normally, you'll create one of these as you verify
the configuration of your program - eg for a server, setting the CA
certificates directory, and setting various other bits and bobs.

=item L<Net::SSLeay::OO::SSL> (C: C<SSL*>)

You have one of these per connection, and when you create one it is
tied to a Context object, taking defaults from the Context object.
Many settings can be made either on the Context object or the SSL
object.  Once you have created this object, you attach it to a
filehandle/socket and then call either C<accept> or C<connect>,
depending on which SSL role you are playing in the connection.

=item L<Net::SSLeay::OO::Constants>

This module allows you to explicitly import SSLeay/OpenSSL constants
for passing to various API methods, so that you don't have to
specify the complete namespace to them.

=item L<Net::SSLeay::OO::Error> (C: <unsigned long>)

This class represents an error from OpenSSL, actually a stack of
errors.  These are raised and printed pretty transparently, but if you
want to pick apart the details of the error you can do so.  There is
no corresponding C struct, but the C<ERR_*> man pages (try C<man -k
ERR_>) handle the integers that OpenSSL passes around internally as
error codes.

=item L<Net::SSLeay::OO::X509> (C: C<X509*>)

This class represents a certificate.  You can't create these with this
module, because of a lack of bindings in L<Net::SSLeay>, but various
things will return them.

=item L<Net::SSLeay::OO::X509::Name> (C: C<X509_NAME*>)

Retrieving things like the "issuer name" from X509 certificates
returns one of these objects; you can then call C<-E<gt>oneline> on
it, or print it to your requirements, to get a usable string.

=item L<Net::SSLeay::OO::X509::Store> (C: C<X509_STORE*>)

This class represents a certificate store.  This would normally
represent a local directory with certificates in it.  Currently the
only way to get one of these is with
L<Net::SSLeay::OO::Context/get_cert_store>.

=item L<Net::SSLeay::OO::X509::Context> (C: C<X509_STORE_CTX*>)

This is a type of object that you get back during certificate
verification.  You probably don't need to use this class unless you
want certificate verification to fail based on custom rules during the
actual handshake.

=item L<Net::SSLeay::OO::Session> (C: C<SSL_SESSION*>)

This seems to represent an actual SSL session; ie, after C<accept> or
C<connect> has succeeded.  This is a pretty uninteresting class.
About all you can do with it is pull out or alter the time the SSL
session was established, and session timeouts.

=item L<Net::SSLeay::OO::Functions>

This is the internal class which splits up the functions in
L<Net::SSLeay> into class-specific packages.

=item C<Net::SSLeay::OO::BIO>

=item C<Net::SSLeay::OO::Cipher>

=item C<Net::SSLeay::OO::Compression>

=item C<Net::SSLeay::OO::PRNG>

=item C<Net::SSLeay::OO::Engine>

=item C<Net::SSLeay::OO::PrivateKey>

=item C<Net::SSLeay::OO::PEM>

=item C<Net::SSLeay::OO::KeyType::DH>

=item C<Net::SSLeay::OO::KeyType::RSA>

These classes are currently all TO-DO.  All I've done is earmarked
these packages in L<Net::SSLeay::OO::Functions> as recipients for the
corresponding L<Net::SSLeay> functions.  There's not a lot of
boilerplate that has to be implemented to make them work, take a look
at some of the implementations of some of the X509 classes to see how
short it can be.  If you make them work, with a test suite, send them
to me and I'll include them in this distribution.

=back

=head1 SOURCE, SUBMISSIONS, SUPPORT

Source code is available from Catalyst:

  git://git.catalyst.net.nz/Net-SSLeay-OO.git

And Github:

  git://github.com/catalyst/Net-SSLeay-OO.git

Please see the file F<SubmittingPatches> for information on preferred
submission format.

Suggested avenues for support:

=over

=item *

Net::SSLeay developer's mailing list
L<http://lists.alioth.debian.org/mailman/listinfo/net-ssleay-devel>

=item *

Contact the author and ask either politely or commercially for help.

=item *

Log a ticket on L<http://rt.cpan.org/>

=back

=head1 AUTHOR AND LICENCE

All code in the L<Net::SSLeay::OO> distribution is written by Sam
Vilain, L<sam.vilain@catalyst.net.nz>.  Development commissioned by NZ
Registry Services.

Copyright 2009, NZ Registry Services.  This module is licensed under
the Artistic License v2.0, which permits relicensing under other Free
Software licenses.

=head2 IMPORTANT LICENSE CONDITIONS

This software is not free; it is encumbered by various restrictions
stemming from OpenSSL and Net::SSLeay.  The bizarre copyright of
Net::SSLeay states to be "under the same terms as OpenSSL", which is
something of a GPL/Artistic/Perl license idiom.  What it means is, if
you make software based on Net::SSLeay, you have to acknowledge the
OpenSSL team as below, even if you use it with a free rewrite of
OpenSSL, or something.  If you did that, the Net::SSLeay license will
effectively compel you to lie.  But that's pretty unlikely so let's
just cut straight to the clauses.

=over

=item B<obnoxious renaming clause>

This module and sub-classes which abstract the interface is almost
certainly covered by these clauses:

 * 4. The names "OpenSSL Toolkit" and "OpenSSL Project" must not be used to
 *    endorse or promote products derived from this software without
 *    prior written permission. For written permission, please contact
 *    openssl-core@openssl.org.

 * 5. Products derived from this software may not be called "OpenSSL"
 *    nor may "OpenSSL" appear in their names without prior written
 *    permission of the OpenSSL Project.

=item B<obnoxious advertising clause>

If you write a program which uses SSL sockets, and then you advertise
it, even if SSL is like a small tick-box item and hardly relevant to
the message you are putting across, heed the following license term:

OpenSSL:

 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgment:
 *    "This product includes software developed by the OpenSSL Project
 *    for use in the OpenSSL Toolkit. (http://www.openssl.org/)"

=back

L<Net::SSLeay::OO::Context>, L<Net::SSLeay::SSL>, L<Net::SSLeay::Error>

=cut

