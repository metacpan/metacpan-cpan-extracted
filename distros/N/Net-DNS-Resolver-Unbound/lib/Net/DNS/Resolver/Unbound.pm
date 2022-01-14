package Net::DNS::Resolver::Unbound;

use strict;
use warnings;

our $VERSION;
$VERSION = '1.01';

=head1 NAME

Net::DNS::Resolver::Unbound - Unbound resolver base for Net::DNS

=head1 SYNOPSIS

    use Net::DNS;
    use Net::DNS::Resolver::Unbound;
    my $resolver = Net::DNS::Resolver::Unbound->new(...);

=head1 DESCRIPTION

Net::DNS::Resolver::Unbound is designed as an extension to an existing Net::DNS installation.

Net::DNS::Resolver::Unbound replaces the Net::DNS::Resolver::Base implementation.

=cut


use base qw(Net::DNS::Resolver DynaLoader);
use Carp;
use IO::Select;

eval { Net::DNS::Resolver::Unbound->bootstrap($VERSION) } || croak $@;


=head1 METHODS

=head2 new

    my $resolver = Net::DNS::Resolver::Unbound->new(
	debug  => 1,
	option => ['logfile', 'mylog.txt'] );

Returns a new Net::DNS::Resolver::Unbound resolver object.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new();
	$self->{ub_ctx} = Net::DNS::Resolver::libunbound::ub_ctx_create();
	while ( my $attr = shift ) {
		my $value = shift;
		my $ref	  = ref($value);
		croak "usage: $class->new( $attr => [...] )"
				if $ref && ( $ref ne 'ARRAY' );
		$self->$attr( $ref ? @$value : $value );
	}
	return $self;
}

sub DESTROY {
	my $self = shift;
	my $ctx	 = $self->{ub_ctx};
	Net::DNS::Resolver::libunbound::ub_wait($ctx);
	Net::DNS::Resolver::libunbound::ub_ctx_delete($ctx);
	return;
}


=head2 search, query, send, bgsend, bgbusy, bgread, bgcancel

See L<Net::DNS::Resolver>.

=cut

sub send {
	my $self = shift;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	my $qname   = $query->name;
	my $qtype   = $query->{qtype};
	my $qclass  = $query->{qclass};

	my $reply = eval {
		my $ctx	   = $self->{ub_ctx};
		my $result = Net::DNS::Resolver::libunbound::ub_resolve( $ctx, $qname, $qtype, $qclass );
		$self->_decode_result( undef, $result );
	};
	$self->errorstring($@);
	return $reply;
}

sub bgsend {
	my $self = shift;
	$self->_reset_errorstring;

	my ($query) = $self->_make_query_packet(@_)->question;
	my $qname   = $query->name;
	my $qtype   = $query->{qtype};
	my $qclass  = $query->{qclass};

	my $handle   = {};
	my $callback = $handle->{anchor} = sub {		# sub{} gets destroyed with $handle
		$handle->{result} = [@_];
	};

	my $ctx = $self->{ub_ctx};
	$handle->{async_id} =
			Net::DNS::Resolver::libunbound::ub_resolve_async( $ctx, $qname, $qtype, $qclass, $callback );
	return $handle;
}

sub bgbusy {
	my ( $self, $handle ) = @_;
	return unless $handle;
	return if exists( $handle->{result} );
	my $ctx = $self->{ub_ctx};
	Net::DNS::Resolver::libunbound::ub_process($ctx)
			if Net::DNS::Resolver::libunbound::ub_poll($ctx);
	return !exists( $handle->{result} );
}

sub bgread {
	my ( $self, $handle ) = @_;
	return unless $handle;

	Net::DNS::Resolver::libunbound::ub_wait( $self->{ub_ctx} ) if &bgbusy;

	my $result = $handle->{result} || [];

	my $reply = $self->_decode_result(@$result);
	undef $handle;
	return $reply;
}


sub bgcancel {
	my ( $self, $handle ) = @_;

	Net::DNS::Resolver::libunbound::ub_cancel( $self->{ub_ctx}, $handle->{async_id} );

	undef $handle;
	return;
}


=head2 option

    $filename = $resolver->option( 'logfile' );
    $resolver->option( 'logfile', $filename );

Get or set Unbound resolver (name,value) context options.

=cut

sub option {
	my ( $self, $name, @value ) = @_;
	my $ctx = $self->{ub_ctx};
	return Net::DNS::Resolver::libunbound::ub_ctx_get_option( $ctx, "$name:" ) unless @value;
	Net::DNS::Resolver::libunbound::ub_ctx_set_option( $ctx, "$name:", @value );
	return;
}


=head2 debug_level

Set verbosity of the debug output directed to stderr.
Level 0 is off, 1 very minimal, 2 detailed, and 3 lots.

=cut

sub debug_level {
	my ( $self, $verbosity ) = @_;
	$self->debug($verbosity);
	Net::DNS::Resolver::libunbound::ub_ctx_debuglevel( $self->{ub_ctx}, $verbosity );
	return;
}


=head2 async_thread

Enable a call to resolve_async() to create a thread to handle work in the background.
If false (by default), a process is forked to handle work in the background.

=cut

sub async_thread {
	my ( $self, $dothread ) = @_;
	Net::DNS::Resolver::libunbound::ub_ctx_async( $self->{ub_ctx}, $dothread );
	return;
}


########################################

sub replyfrom { return "(local) Unbound resolver" }


sub _decode_result {
	my ( $self, $err, $result ) = @_;

	$self->errorstring( Net::DNS::Resolver::libunbound::ub_strerror($err) ) if $err;

	my $answer;
	if ($result) {
		my $packet = Net::DNS::Resolver::libunbound::ub_result_packet($result);
		$answer = Net::DNS::Packet->decode( \$packet, $self->debug );
		$self->errorstring($@);
		$answer->from( $self->replyfrom );
		Net::DNS::Resolver::libunbound::ub_resolve_free($result);
	}

	return $answer;
}


1;
__END__


=head1 COPYRIGHT

Copyright (c)2022 Dick Franks

All Rights Reserved


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl>, L<Net::DNS>, L<Net::DNS::Resolver>,
L<Unbound|https://unbound.docs.nlnetlabs.nl/en/latest>

=cut

