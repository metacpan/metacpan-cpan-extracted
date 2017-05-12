
package Net::SSLGlue::Socket;
our $VERSION = 1.002;

use strict;
use warnings;
use Carp 'croak';
use Symbol 'gensym';
use IO::Socket::SSL;
my $IPCLASS;
BEGIN {
    for(qw(IO::Socket::IP IO::Socket::INET6 IO::Socket::INET)) {
	$IPCLASS = $_,last if eval "require $_";
    }
}

# this can be overwritten (with local) to get arguments passed around
# to strict calls of the socket class new
our %ARGS;

sub new {
    my $class = shift;
    my %args = @_>1 ? @_ : ( PeerAddr => shift() );
    %args = ( %args, %ARGS );

    my %sslargs;
    for(keys %args) {
	$sslargs{$_} = delete $args{$_} if m{^SSL_};
    }

    my $ssl = delete $args{SSL};
    my $sock = $ssl
	? IO::Socket::SSL->new(%args,%sslargs)
	: $IPCLASS->new(%args)
	or return;

    my $self = gensym();
    bless $self,$class;
    ${*$self}{sock}    = $sock;
    ${*$self}{ssl}     = $ssl;
    ${*$self}{sslargs} = \%sslargs;
    tie *{$self}, "Net::SSLGlue::Socket::HANDLE", $self;

    return $self;
}

sub DESTROY {
    my $self = shift;
    %{*$self} = ();
}

for my $sub (qw(
    fileno sysread syswrite close connect fcntl
    read write readline print printf getc say eof getline getlines
    blocking autoflush timeout
    sockhost sockport peerhost peerport sockdomain
    truncate stat setbuf setvbuf fdopen ungetc send recv
)) {
    no strict 'refs';
    *$sub = sub {
	my $self = shift;
	my $sock = ${*$self}{sock} or return;
	my $sock_sub = $sock->can($sub) or croak("$sock does not support $sub");
	unshift @_,$sock;
	# warn "*** $sub called";
	goto &$sock_sub;
    };
}

sub accept {
    my ($self,$class) = @_;
    my $sock = ${*$self}{sock} or return;
    my $conn = $sock->accept();

    return bless $conn,$class 
	if $class && ! $class->isa('Net::SSLGlue::Socket');

    $class ||= ref($self);
    my $wrap = gensym;
    *$wrap = *$conn;   # clone original handle
    bless $wrap, $class;
    ${*$wrap}{sock}    = $conn;
    ${*$wrap}{ssl}     = ${*$self}{ssl};
    ${*$wrap}{sslargs} = ${*$self}{sslargs};
    return $wrap;
};

sub start_SSL {
    my ($self,%args) = @_;
    croak("start_SSL called on SSL socket") if ${*$self}{ssl};

    %args = (%{${*$self}{sslargs}},%args);
    if (my $ctx = $args{SSL_reuse_ctx}) {
	# take the context from the attached socket
	$args{SSL_reuse_ctx} = ${*$ctx}{sock}
	    if $ctx->isa('Net::SSLGlue::Socket');
    }
    IO::Socket::SSL->start_SSL(${*$self}{sock},%args) or return;
    ${*$self}{ssl} = 1;
    return $self;
}

sub stop_SSL {
    my $self = shift;
    croak("stop_SSL called on plain socket") if ! ${*$self}{ssl};
    ${*$self}{sock}->stop_SSL(@_) or return;
    ${*$self}{ssl} = 0;
    return $self;
}

sub can_read {
    my ($self,$timeout) = @_;
    return 1 if ${*$self}{ssl} && ${*$self}{sock}->pending;
    vec( my $vec,fileno(${*$self}{sock}),1) = 1;
    return select($vec,undef,undef,$timeout);
}

sub peer_certificate {
    my $self = shift;
    return ${*$self}{ssl} && ${*$self}{sock}->peer_certificate(@_);
}

sub is_ssl {
    my $self = shift;
    return ${*$self}{ssl} && ${*$self}{sock};
}

package Net::SSLGlue::Socket::HANDLE;
use strict;
use Errno 'EBADF';
use Scalar::Util 'weaken';

sub TIEHANDLE {
    my ($class, $handle) = @_;
    weaken($handle);
    bless \$handle, $class;
}

sub READ     { ${shift()}->sysread(@_) }
sub READLINE { ${shift()}->readline(@_) }
sub GETC     { ${shift()}->getc(@_) }
sub PRINT    { ${shift()}->print(@_) }
sub PRINTF   { ${shift()}->printf(@_) }
sub WRITE    { ${shift()}->syswrite(@_) }
sub FILENO   { ${shift()}->fileno(@_) }
sub TELL     { $! = EBADF; return -1 }
sub BINMODE  { return 0 }  # not perfect, but better than not implementing the method
sub CLOSE {                          #<---- Do not change this function!
    my $ssl = ${$_[0]};
    local @_;
    $ssl->close();
}


1;

=head1 NAME

Net::SSLGlue::Socket - socket which can be either SSL or plain IP (IPv4/IPv6)

=head1 SYNOPSIS

    use Net::SSLGlue::Socket;
    # SSL right from start
    my $ssl = Net::SSLGlue::Socket->new(
	PeerHost => ...,  # IPv4|IPv6 address
	PeerPort => ...,
	SSL => 1,
	SSL_ca_path => ...
    );

    # SSL through upgrade of plain connection
    my $plain = Net::SSLGlue::Socket->new(...);
    $plain->start_SSL( SSL_ca_path => ... );
    ...
    $plain->stop_SSL


=head1 DESCRIPTION

First, it is recommended to use L<IO::Socket::SSL> directly instead of this
module, since this kind of functionality is available in IO::Socket::SSL since
version 1.994.

L<Net::SSLGlue::Socket> implements a socket which can be either plain or SSL.
If IO::Socket::IP or IO::Socket::INET6 are installed it will also transparently
handle IPv6 connections.

A socket can be either start directly with SSL or it can be start plain and
later be upgraded to SSL (because of a STARTTLS commando or similar) and also
downgraded again.

It is possible but not recommended to use the socket in non-blocking
mode, because in this case special care must be taken with SSL (see
documentation of L<IO::Socket::SSL>).

Additionally to the usual socket methods the following methods are defined or
extended:

=head1 METHODS

=over 4

=item new

The method C<new> of L<Net::SSLGlue::Socket> can have the argument SSL. If this
is true the SSL upgrade will be done immediatly. If not set any SSL_* args will
still be saved and used at a later start_SSL call.

=item start_SSL

This will upgrade the plain socket to SSL. See L<IO::Socket::SSL>  for
arguments to C<start_SSL>. Any SSL_* arguments given to new will be applied
here too.

=item stop_SSL

This will downgrade the socket from SSL to plain.

=item peer_certificate ...

Once the SSL connection is established you can use this method to get
information about the certificate. See the L<IO::Socket::SSL> documentation.

=item can_read(timeout)

This will check for available data. For a plain socket this will only use
C<select> to check the socket, but for SSL it will check if there are any
pending data before trying a select.
Because SSL needs to read the whole frame before decryption can be done, a
successful return of can_read is no guarantee that data can be read
immediatly, only that new data are either available or in the process of
arriving.

=back

=head1 SEE ALSO

IO::Socket::SSL

=head1 COPYRIGHT

This module is copyright (c) 2013..2015, Steffen Ullrich.
All Rights Reserved.
This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.
