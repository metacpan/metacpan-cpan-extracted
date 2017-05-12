
package Net::SSLeay::OO::SSL;

use Moose;
use Net::SSLeay::OO::Context;

=head1 NAME

Net::SSLeay::OO::SSL - OO interface to Net::SSLeay methods

=head1 SYNOPSIS

 use Net::SSLeay::OO::Constants qw(OP_ALL);
 use Net::SSLeay::OO::SSL;

 # basic (insecure!) use - see below
 my $ssl = Net::SSLeay::OO::SSL->new;
 $ssl->set_fd(fileno($socket));
 $ssl->connect;

=head1 DESCRIPTION

This module adds some OO niceties to using the Net::SSLeay / OpenSSL
SSL objects.

This SSL object is a per-connection entity.  In general you will
create one of these from a L<Net::SSLeay::OO::Context> object which you
set up for your process and perhaps configured more fully.

If you do not do that, then you are not certifying the authenticity of
the peer.  This means that your program will be vulnerable to MITM
(man in the middle) attacks.

=cut

=head1 ATTRIBUTES

=over

=item ssl : Int

The raw *SSL pointer.  Use at your own risk.

=cut

has 'ssl'        => isa => "Int",
	is       => "ro",
	required => 1,
	lazy     => 1,
	default  => sub {
	my $self = shift;
	Net::SSLeay::new( $self->ctx->ctx );
	},
	;

=item ctx : Context

A Net::SSLeay::OO::Context object.  Automatically created if not assigned
on creation of the Net::SSLeay::OO::SSL.

=cut

has 'ctx'        => isa => "Net::SSLeay::OO::Context",
	is       => "ro",
	required => 1,
	default  => sub {
	Net::SSLeay::OO::Context->new();
	},
	;

sub BUILD {
	my $self = shift;
	$self->ssl;
}

=back

=cut

sub DESTROY {
	my $self = shift;
	if ( $self->ssl ) {
		$self->free;
		delete $self->{ssl};
	}
}

=head1 METHODS

All of the methods in Net::SSLeay which are not obviously a part of
some other class are converted to methods of the Net::SSLeay::OO::SSL
class.

The documentation that follows is a core set, sufficient for running
up a server and verifying client certificates.  However most functions
from the OpenSSL library are actually imported.

=cut

=head2 Handshake configuration methods

These options are all intended to control the handshake phase of SSL
negotiations.

=over

=item B<set_options( OP_XXX & OP_XXX ... )>

=item B<get_options()>

=item B<set_verify( $mode, [$verify_callback] )>

=item B<use_certificate( Net::SSLeay::OO::X509 $cert )>

=item B<use_certificate_file( $filename, $type )>

=item B<use_PrivateKey_file( $filename, $type )>

These functions are all very much the same as in
C<Net::SSLeay::OO::Context> but apply only to this SSL object.  Note that
some functions are not available, such as
C<use_certificate_chain_file()> and C<set_default_cb_passwd()>

=back

=cut

has 'verify_cb', is => "ro";

BEGIN {
	no strict 'refs';
	*$_ = \&{"Net::SSLeay::OO::Context::$_"}
		for qw(set_verify use_certificate);
}

sub _set_verify {
	my $self    = shift;
	my $mode    = shift;
	my $real_cb = shift;
	my $ssl     = $self->ssl;
	$self->{verify_cb} = $real_cb;
	Net::SSLeay::set_verify( $ssl, $mode, $real_cb );
}

=head2 Setup methods

These methods set up the SSL object within your process - connecting
it to filehandles and so on.

=over

=item B<set_fd( fileno($fh) )>

=item B<get_fd( fileno($fh) )>

Sets/Gets the file descriptor number for send and receive.

=item B<set_rfd( fileno($fh) )>

=item set_wfd( fileno($fh) )>

Specify the file descriptors for send and receive independently.
Useful when dealing with non-socket entities such as pipes.

=item B<set_read_ahead( $boolean )>

=item B<get_read_ahead()>

See L<SSL_set_read_ahead(3ssl)>

=item B<set_mode( $mode )>

=item B<get_mode()>

Sets/gets the mode of the SSL object.  See L<SSL_set_mode(3ssl)>.  If
you want non-blocking use, set:

   $ssl->set_mode( MODE_ENABLE_PARTIAL_WRITE |
                   MODE_ACCEPT_MOVING_WRITE_BUFFER );

See F<t/05-non-blocking.t> for a more complete example of using this
library in non-blocking mode.  Note you still need to mark the
underlying filehandle as non-blocking.

=back

=head2 Handshake/SSL session methods

=over

=item B<accept()>

=item B<connect()>

Initiate the SSL session, from the perspective of a server or a
client, respectively.

=item B<clear()>

Forget the current SSL session.  You probably don't want to use this.

=item B<shutdown()>

Sends a "close notify" shutdown alert to the peer.  You should do this
before you shut down the underlying socket.

=back

=head2 IO functions

=over

=item B<ssl_read_all>

=item B<ssl_read_CRLF( $max_length? )>

=item B<ssl_read_until( $delimit?, $max_length? )>

These are L<Net::SSLeay> wrappers to the OpenSSL read methods; use
these if you are not sure how to use the other ones.  These are
blocking calls.  Note that C<ssl_read_all> will read from the socket
until the remote end shuts down.  C<ssl_read_CRLF> and
C<ssl_read_until> use the undocumented OpenSSL function C<SSL_peek> to
read the entire pending buffer, figure out at what point the delimiter
appears and then C<SSL_read> just enough to clear that.

=item B<read($max?)>

Perform and return read of the rest of the next SSL record, or C<$max>
bytes, whichever is smaller.  How large that record is depends on the
sender, but you need to receive an entire record before you can
extract any data from it anyway.

=item B<peek($max?)>

Like C<read()>, but doesn't clear the data from the session buffer.

=item B<ssl_write_all($message)>

=item B<ssl_write_CRLF($line)>

Convenience wrappers for writing a message or a single line to the
socket via SSL.  Note that C<ssl_write_CRLF> sends the CRLF two-byte
sequence to OpenSSL in its own C<SSL_write> function call, with a
comment warning that this "uses less memory but might use more network
packets".

=item B<write($message)>

Pretty much a direct method for C<SSL_write>; writes the message and
returns the number of bytes written.

=item B<write_partial($from, $count, $message)>

Writes a substring of the message and returns the number of bytes
written.

This interface is probably unnecessary since about Perl 5.8.1, as on
those perls C<substr()> can refer to substrings of other strings.

=back

=head2 Informative methods

These methods return information about the current SSL object

=over

=item B<get_error>

Returns the error from the last IO operation, you can match this
against various constants as described on L<SSL_get_error(3ssl)>.

=item B<want>

A simpler version of C<get_error>, see C<SSL_want(3ssl)>.

=item B<get_cipher>

The cipher of the current session

=item B<get_peer_certificate>

Returns a L<Net::SSLeay::OO::X509> object corresponding to the peer
certificate; if you're a client, it's the server certificate.  If
you're a server, it's the client certificate, if you requested it
during handshake with C<set_verify>.

=cut

sub get_peer_certificate {
	my $self = shift;
	my $x509 = Net::SSLeay::get_peer_certificate( $self->ssl );
	&Net::SSLeay::OO::Error::die_if_ssl_error("get_peer_certificate");
	if ($x509) {
		Net::SSLeay::OO::X509->new( x509 => $x509 );
	}
}

=item B<get_session>

Returns a Net::SSLeay::OO::Session object corresponding to the SSL
session.  This actually calls C<SSL_get1_session> to try to help save
you from segfaults.

=item B<set_session($session)>

If for some reason you want to set the session, call this method,
passing a Net::SSLeay::OO::Session object.

=cut

sub get_session {
	my $self = shift;
	require Net::SSLeay::OO::Session;
	my $sessid = Net::SSLeay::get1_session( $self->ssl );
	&Net::SSLeay::OO::Error::die_if_ssl_error("get_session");
	if ($sessid) {
		Net::SSLeay::OO::Session->new( session => $sessid );
	}
}

sub set_session {
	my $self    = shift;
	my $session = shift;
	Net::SSLeay::set_session( $self->ssl, $session->session );
	&Net::SSLeay::OO::Error::die_if_ssl_error("set_session");
}

=item B<state_string>

=item B<state_string_long>

Return a codified or human-readable string 'indicating the current
state of the SSL object'.

L<SSL_state_string(3ssl)> sez ''Detailed description of possible
states to be included later''

=item B<rstate_string>

=item B<rstate_string_long>

Return information about the read state.  In a blocking environment,
this should always return "RD" or "read done".  Otherwise, you'll get
something else possibly informative.

=back

=head2 Un-triaged

The following methods I haven't looked at at all; if you use them in a
program, please submit a patch which moves them into one of the above
categories.  The best information about them will be found on the
relevant SSL man page - use C<man -k> or C<apropros> to find a useful
man page.

My policy on these is that no function should take an unwrapped
pointer argument or return an unwrapped pointer.  So long as the
function you use doesn't do that, you can reasonably expect its call
interface not to change; but of course I place no guarantees should
OpenSSL or Net::SSLeay ruin your day.

 set_cipher_list($list)
 add_client_CA(ssl,x)
 alert_desc_string(value)
 alert_desc_string_long(value)
 alert_type_string(value)
 alert_type_string_long(value)
 callback_ctrl(ssl,i,fp)
 check_private_key(ctx)
 do_handshake(s)
 dup(ssl)
 get_current_cipher(s)
 get_default_timeout(s)
 get_ex_data(ssl,idx)
 get_finished(s,buf,count)
 get_peer_finished(s,buf,count)
 get_quiet_shutdown(ssl)
 get_shutdown(ssl)
 get_verify_depth(s)
 get_verify_mode(s)
 get_verify_result(ssl)
 renegotiate(s)
 set_accept_state(s)
 set_client_CA_list(s,list)
 set_connect_state(s)
 set_ex_data(ssl,idx,data)
 set_info_callback(ssl,cb)
 set_purpose(s,purpose)
 set_quiet_shutdown(ssl,mode)
 set_shutdown(ssl,mode)
 set_trust(s,trust)
 set_verify_depth(s,depth)
 set_verify_result(ssl,v)
 version(ssl)
 load_client_CA_file(file)
 add_file_cert_subjects_to_stack(stackCAs,file)
 add_dir_cert_subjects_to_stack(stackCAs,dir)
 set_session_id_context(ssl,sid_ctx,sid_ctx_len)
 set_tmp_rsa_callback(ssl, cb)
 set_tmp_dh_callback(ssl,dh)
 get_ex_new_index(argl, argp, new_func, dup_func, free_func)
 clear_num_renegotiations(ssl)
 get_app_data(s)
 get_cipher_bits(s,np)
 get_mode(ssl)
 get_state(ssl)
 need_tmp_RSA(ssl)
 num_renegotiations(ssl)
 session_reused(ssl)
 set_app_data(s,arg)
 set_mode(ssl,op)
 set_pref_cipher(s,n)
 set_tmp_dh(ssl,dh)
 set_tmp_rsa(ssl,rsa)
 total_renegotiations(ssl)
 get_client_random(s)
 get_server_random(s)
 get_keyblock_size(s)
 set_hello_extension(s, type, data)
 set_session_secret_cb(s,func,data=NULL)

=cut

# excluded because they were either named badly for their argument
# types, because I didn't want to implement versions which would have
# to take pointers directly as integers, because there was no OpenSSL
# man page for them, or because they were marked as not for general
# consumption.

use Net::SSLeay::OO::Functions 'ssl', -exclude => [
	qw( get_time set_time get_timeout set_timeout
		set_bio get_rbio get_wbio get0_session
		get1_session ctrl callback_ctrl state
		set_ssl_method get_ssl_method set_cert_and_key
		)
];

1;

__END__

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::Context>, L<Net::SSLeay::Session>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:
# vim: filetype=perl:noexpandtab:ts=3:sw=3
