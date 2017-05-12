
package Net::SSLeay::OO::Context;

use Moose;

use Net::SSLeay;
use Net::SSLeay::OO::Error;

=head1 NAME

Net::SSLeay::OO::Context - OO interface to Net::SSLeay CTX_ methods

=head1 SYNOPSIS

 use Net::SSLeay::OO::Constants qw(OP_ALL FILETYPE_PEM OP_NO_SSLv2);
 use Net::SSLeay::OO::Context;

 # create an SSL object, disable SSLv2
 my $ctx = Net::SSLeay::OO::Context->new;
 $ctx->set_options(OP_ALL & OP_NO_SSLv2);

 # specify path to your CA certificates for verifying peer
 $ctx->load_verify_locations($ca_filename, $db_dir);

 # optional for clients - load our own certificate/key
 $ctx->use_certificate_chain_file($cert_filename);
 $ctx->use_PrivateKey_file($key_filename, FILETYPE_PEM);

 # optional for servers - require peer certificates
 $ctx->set_verify(VERIFY_PEER & VERIFY_FAIL_IF_NO_PEER_CERT);

 # now make SSL objects with these options!
 use Net::SSLeay::OO::SSL;
 my $ssl = Net::SSLeay::OO::SSL->new( ctx => $ctx );

 # convenience method for the above, plus attach to a socket
 my $ssl = $ctx->new_ssl($socket);

=head1 DESCRIPTION

Every SSL connection has a context, which specifies various options.
You can also specify these options on Net::SSLeay::OO::SSL objects, but
you would normally want to set up as much as possible early on, then
re-use the context to create new SSL handles.

The OpenSSL library initialization functions are called the first time
that a Net::SSLeay::OO::Context object is instantiated.

=cut

has 'ctx' => (
	is  => "ro",
	isa => "Int",
);

=head1 ATTRIBUTES

=over

=item ctx : Int

The raw ctx object.  Use at your own risk.

=item ssl_version: ( undef | 2 | 3 | 10 )

Specify the SSL version to allow.  10 means TLSv1, 2 and 3 mean SSLv2
and SSLv3, respectively.  No options means 'SSLv23'; if you want to
permit the secure protocols only (SSLv3 and TLSv1) you need to use:

  use Net::SSLeay::OO::Constants qw(OP_NO_SSLv2);
  my $ctx = Net::SSLeay::OO::Context->new();
  $ctx->set_options( OP_NO_SSLv2 )

This option must be specified at object creation time.

=back

=cut

has 'ssl_version' => (
	is  => "ro",
	isa => "Int",
);

our $INITIALIZED;

sub BUILD {
	my $self = shift;
	if ( !$INITIALIZED++ ) {
		Net::SSLeay::load_error_strings();
		Net::SSLeay::SSLeay_add_ssl_algorithms();
		Net::SSLeay::randomize();
	}
	if ( !$self->ctx ) {
		my $ctx = Net::SSLeay::new_x_ctx( $self->ssl_version );
		$self->{ctx} = $ctx;
		$self->set_default_verify_paths;
	}
}

sub DESTROY {
	my $self = shift;
	if ( $self->ctx ) {
		$self->free;
		delete $self->{ctx};
	}
}

=head1 METHODS

All of the CTX_ methods in Net::SSLeay are converted to methods of
the Net::SSLeay::OO::Context class.

The documentation that follows is a core set, sufficient for running
up a server and verifying client certificates.  However most functions
from the OpenSSL library are actually imported.

=head2 Handshake configuration methods

=over

=item B<set_options(OP_XXX | OP_XXX ...)>

Set options that apply to this Context.  The valid values and
descriptions can be found on L<SSL_CTX_set_options(3ssl)>; for this
module they must be imported from L<Net::SSLeay::OO::Constants>.

=item B<get_options()>

Returns the current options bitmask; mask with the option you're
interested in to see if it is set:

  unless ($ctx->get_options & OP_NO_SSLv2) {
      die "SSL v2 was not disabled!";
  }

=item B<load_verify_locations($filename, $path)>

Specify where CA certificates in PEM format are to be found.
C<$filename> is a single file containing one or more certificates.
C<$path> refers to a directory with C<9d66eef0.1> etc files as would
be made by L<c_rehash>.  See L<SSL_CTX_load_verify_locations(3ssl)>.

=item B<set_default_verify_paths()>

Sets up system-dependent certificate store location.  This is probably
quite a good default.

=item B<set_verify($mode, [$verify_callback])>

Mode should be either VERIFY_NONE, or a combination of VERIFY_PEER,
VERIFY_CLIENT_ONCE and/or VERIFY_FAIL_IF_NO_PEER_CERT.  If you don't
set this as a server, you cannot later call
C<-E<gt>get_peer_certificate> to find out if the client configured a
certificate (though there are references to repeating SSL negotiation,
eg in L<SSL_read(3ssl)>, not sure how this is performed though).

During the handshake phase, the $verify_callback is called once for
every certificate in the chain of the peer, starting with the root
certificate.  Each time, it is passed two arguments: the first a
boolean (1 or 0) which indicates whether the in-built certificate
verification passed, and the second argument is the actual
B<certficate> which is being verified (a L<Net::SSLeay::OO::X509> object).
Note this is different to the calling convention of OpenSSL and
Net::SSLeay, which instead (logically, anyway) pass a
L<Net::SSLeay::OO::X509::Context> object.  However there is little of
interest in this other object, so for convenience the current
certificate is passed instead as the second object.  The
L<Net::SSLeay::OO::X509::Context> is passed as a third argument should you
need it.

The passed L<Net::SSLeay::OO::X509> object will not work outside of the
callback; get everything out of it that you need inside it, or use the
C<get_peer_certificate> method of L<Net::SSLeay::OO::SSL> later.

Example:

   my @names;
   $ctx->set_verify(VERIFY_PEER, sub {
       my ($ok, $x509) = @_;
       push @names, $x509->subject_name->cn;
       return $ok;
   });

   $ssl = $ctx->new_ssl($fd);
   $ssl->accept();

   print "Client identity chain: @names\n";

=cut

use Net::SSLeay::OO::Constants qw(VERIFY_NONE);

has 'verify_cb', is => "ro";

sub set_verify {
	my $self     = shift;
	my $mode     = shift;
	my $callback = shift;
	require Net::SSLeay::OO::X509::Context;

	# always set a callback, unless VERIFY_NONE "is set"
	my $real_cb = $mode == VERIFY_NONE ? undef : sub {
		my ( $preverify_ok, $x509_store_ctx ) = @_;
		my $x509_ctx =
			Net::SSLeay::OO::X509::Context->new(
			x509_store_ctx => $x509_store_ctx,);
		my $cert = $x509_ctx->get_current_cert;
		my $ok;
		if ($callback) {
			$ok = $callback->( $preverify_ok, $cert, $x509_ctx );
		}
		else {
			$ok = $preverify_ok;
		}
		$cert->free;
		$ok;
	};
	$self->_set_verify( $mode, $real_cb );
	&Net::SSLeay::OO::Error::die_if_ssl_error("set_verify");
}

sub _set_verify {
	my $self    = shift;
	my $mode    = shift;
	my $real_cb = shift;
	my $ctx     = $self->ctx;
	$self->{verify_cb} = $real_cb;
	Net::SSLeay::CTX_set_verify( $ctx, $mode, $real_cb );
}

=item use_certificate_file($filename, $type)

C<$filename> is the name of a local file.  This becomes your local
cert - client or server.

C<$type> may be FILETYPE_PEM or FILETYPE_ASN1.

=item use_certificate_chain_file($filename)

C<$filename> is the name of a local PEM file, containing a chain of
certificates which lead back to a valid root certificate.  In general,
this is the more useful method of loading a certificate.

=item use_PrivateKey_file($filename, $type);

If using a certificate, you need to specify the private key of the end
of the chain.  Specify it here; set C<$type> as with
C<use_certificate_file>

=back

=head2 Setup methods

=over

=item B<set_mode($mode)>

=item B<get_mode>

Sets/gets the mode of SSL objects created from this context.  See
L<SSL_set_mode(3ssl)>.  This is documented more fully at
L<Net::SSLeay::OO::SSL/set_mode>

=back

=head2 Handshake/SSL session methods

=over

=item B<new_ssl($socket)>

Makes a new L<Net::SSLeay::OO::SSL> object using this Context, and attach
it to the given socket (if passed).

=cut

sub new_ssl {
	my $self   = shift;
	my $socket = shift;
	my $ssl    = Net::SSLeay::OO::SSL->new( ctx => $self );
	if ($socket) {
		$ssl->set_fd( fileno($socket) );
	}
	$ssl;
}

=item B<connect($socket)>

=item B<accept($socket)>

Further convenience methods, which create a new L<Net::SSLeay::OO::SSL>
object, wire it up to the passed socket, then call either C<connect>
or C<accept>.  Returns the L<Net::SSLeay::OO::SSL> object.

=cut

sub connect {
	my $self = shift;
	my $ssl  = $self->new_ssl(@_);
	$ssl->connect();
	$ssl;
}

sub accept {
	my $self = shift;
	my $ssl  = $self->new_ssl(@_);
	$ssl->accept();
	$ssl;
}

=back

=head1 Informative methods

=over

=item B<get_cert_store()>

Returns the L<Net::SSLeay::OO::X509::Store> associated with this context.

=cut

sub get_cert_store {
	my $self = shift;
	require Net::SSLeay::OO::X509::Store;
	my $store = Net::SSLeay::CTX_get_cert_store( $self->ctx ),
		&Net::SSLeay::OO::Error::die_if_ssl_error("get_cert_store");
	Net::SSLeay::OO::X509::Store->new( x509_store => $store );
}

=back

=cut

use Net::SSLeay::OO::Functions "ctx",
	-include => { set_cert_and_key => "set_cert_and_key" };

1;

__END__

=head2 un-triaged

The following methods were defined in Net::SSLeay 1.35, and may work
via this interface.

 v2_new()
 v3_new()
 v23_new()
 tlsv1_new()
 new_with_method(meth)
 add_session(ctx,ses)
 remove_session(ctx,ses)
 flush_sessions(ctx,tm)
 use_RSAPrivateKey_file(ctx,file,type)
 set_cipher_list(s,str)
 ctrl(ctx,cmd,larg,parg)
 get_options(ctx)
 set_options(ctx,op)
 sessions(ctx)
 sess_number(ctx)
 sess_connect(ctx)
 sess_connect_good(ctx)
 sess_connect_renegotiate(ctx)
 sess_accept(ctx)
 sess_accept_renegotiate(ctx)
 sess_accept_good(ctx)
 sess_hits(ctx)
 sess_cb_hits(ctx)
 sess_misses(ctx)
 sess_timeouts(ctx)
 sess_cache_full(ctx)
 sess_get_cache_size(ctx)
 sess_set_cache_size(ctx,size)
 add_client_CA(ctx,x)
 callback_ctrl(ctx,i,fp)
 check_private_key(ctx)
 get_ex_data(ssl,idx)
 get_quiet_shutdown(ctx)
 get_timeout(ctx)
 get_verify_depth(ctx)
 get_verify_mode(ctx)
 set_cert_store(ctx,store)
 get_cert_store(ctx)
 set_cert_verify_callback(ctx,func,data=NULL)
 set_client_CA_list(ctx,list)
 set_default_passwd_cb(ctx,func=NULL)
 set_default_passwd_cb_userdata(ctx,u=NULL)
 set_ex_data(ssl,idx,data)
 set_purpose(s,purpose)
 set_quiet_shutdown(ctx,mode)
 set_ssl_version(ctx,meth)
 set_timeout(ctx,t)
 set_trust(s,trust)
 set_verify_depth(ctx,depth)
 use_RSAPrivateKey(ctx,rsa)
 get_ex_new_index(argl,argp,new_func,dup_func,free_func)
 set_session_id_context(ctx,sid_ctx,sid_ctx_len)
 set_tmp_rsa_callback(ctx, cb)
 set_tmp_dh_callback(ctx, dh)
 add_extra_chain_cert(ctx,x509)
 get_app_data(ctx)
 get_mode(ctx)
 get_read_ahead(ctx)
 get_session_cache_mode(ctx)
 need_tmp_RSA(ctx)
 set_app_data(ctx,arg)
 set_mode(ctx,op)
 set_read_ahead(ctx,m)
 set_session_cache_mode(ctx,m)
 set_tmp_dh(ctx,dh)
 set_tmp_rsa(ctx,rsa)

=head1 AUTHOR

Sam Vilain, L<samv@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009  NZ Registry Services

This program is free software: you can redistribute it and/or modify
it under the terms of the Artistic License 2.0 or later.  You should
have received a copy of the Artistic License the file COPYING.txt.  If
not, see <http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

L<Net::SSLeay::OO>, L<Net::SSLeay::OO::Constants>, L<Net::SSLeay::SSL>,
L<Net::SSLeay::OO::X509>, L<Net::SSLeay::Error>

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
