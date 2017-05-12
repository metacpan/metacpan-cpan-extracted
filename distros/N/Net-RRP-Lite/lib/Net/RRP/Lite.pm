package Net::RRP::Lite;

use strict;
use vars qw($VERSION $DEBUG);
$VERSION = '0.02';
$DEBUG = 0;
use Net::RRP::Lite::Response;

use constant CRLF => "\r\n";
use constant END_MARK => qr/\r\n\.\r\n/;
use constant READ_LEN => 64;

__PACKAGE__->_mk_commands(qw(add check del describe mod quit renew session status transfer));

sub new {
    my($class, $sock) = @_;
    my $self = bless {_sock => $sock}, $class;
    $self->_read_until(END_MARK); # READ HELLO.
    return $self;
}

sub connect {
    my($class, %args) = @_;
    require IO::Socket::SSL;
    my $sock = IO::Socket::SSL->new(%args) 
	or _croak("could not make socket:$!");
    return $class->new($sock);
}

sub login {
    my($self, $registrer, $password) = @_;
    $self->request('SESSION', undef, {
	-Id => $registrer,
	-Password => $password,
    });
}

sub disconnect {
    my $self = shift;
    my $res = $self->request('QUIT');
    $self->{_sock}->close;
    return $res;
}

sub request {
    my($self, $command, $entity, $args) = @_;
    $self->_write_sock(sprintf("%s". CRLF, lc($command)));
    $self->_write_sock(sprintf("EntityName:%s". CRLF, $entity)) if $entity;
    if (ref($args) eq 'HASH') {
	while (my($key, $val) = each %$args) {
	    if (ref($val) eq 'ARRAY') {
		for my $v(@$val) {
		    $self->_write_sock(sprintf("%s:%s". CRLF, $key, $v));
		}
	    }
	    else {
		$self->_write_sock(sprintf("%s:%s". CRLF, $key, $val));
	    }
	}
    }
    $self->_write_sock(".". CRLF);
    my $result_data = $self->_read_until(END_MARK);
    return Net::RRP::Lite::Response->new($result_data);
}

sub _read_until {
    my($self, $stop) = @_;
    my $line = "";
    my $buf = "";
    my $len = 0;
    while (my $len = $self->{_sock}->sysread($line, READ_LEN)) {
	$buf .= $line;
	if ($buf =~ m/$stop/s) {
	    if ($DEBUG) {
		warn "S:$_\r\n" for(split(/\r\n/, $`));
	    }
	    return $`;
	}
    }
    _croak("could not read data") unless $len;
}

sub _write_sock {
    my($self, $data) = @_;
    warn "C:$data" if $DEBUG;
    $self->{_sock}->print($data);
}

sub _mk_commands {
    my($class, @commands) = @_;
    no strict 'refs';
    for my $command(@commands) {
	*{"$class\:\:$command"} = sub {
	    my($self, $entity, $args) = @_;
	    $self->request($command, $entity, $args);
	}
    }
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

1;
__END__

=head1 NAME

Net::RRP::Lite - simple interface of RRP.

=head1 SYNOPSIS

  use Net::RRP::Lite;
  use IO::Socket::SSL;

  my $sock = IO::Socket::SSL->new(
      PeerHost => '....',
      PeerPort => '....',
      #....
  );
  my $rrp = Net::RRP::Lite->new($sock);
  $rrp->login('registrer', 'xxxx');
  my $res = $rrp->check(Domain => {
      DomainName => 'example.com',
  });
  $rrp->disconnect;

=head1 DESCRIPTION

Net::RRP::Lite provides a simple interface of Registry Registrar Protocol.
RRP has four elements, Command, Entity, Attributes and Options.

Net::RRP::Lite generates method dynamically, and method structure is below.

$rrp->I<command_name>(I<Entity> => { Attributes and Options });

=head2 EXAMPLES

C represents data sent by client, S represents data received from server.

   C:add<crlf>
   C:EntityName:Domain<crlf>
   C:DomainName:example.com<crlf>
   C:-Period:10<crlf>
   C:.<crlf>
   S:200 Command completed successfully<crlf>
   S:registration expiration date:2009-09-22 10:27:00.0<crlf>
   S:status:ACTIVE<crlf>
   S:.<crlf>

   my $rrp = Net::RRP::Lite->new($sock);
   my $res = $rrp->add(Domain => 
                       { DomainName => 'example.com', -Period => 10});
   print $res->code; # 200
   print $res->message; # Command completed successfully
   print $res->param('registration expiration date') 
   print $res->param('status');

=head1 METHODS

=over 4

=item new($sock)

constructor of Net::RRP::Lite object. $sock is a IO::Socket::SSL object.

=item connect(%options)

connect RRP Server and construct new Net::RRP::Lite object.
%options are passed to IO::Socket::SSL.

=item $rrp->login($id, $password)

shortcut for $rrp->session(undef, { -Id => $id, -Password => $password});

=item $rrp->disconnect;

send quit command and close socket.

=back

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::RRP> RFC2832

=cut
