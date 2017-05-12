package Net::QMQP;

use strict;
use vars qw($VERSION);
use Carp;
use IO::Socket;

$VERSION = "0.01";

use base qw( Class::Accessor );

__PACKAGE__->mk_accessors( qw(sender recipients host message timeout port debug) );

sub new
{
    my $self = shift;
    my $type = ref($self) || $self;
    my %args = @_;

    my $obj = $type->SUPER::new(\%args);

    $obj->{host}    ||= 'localhost';
    $obj->{timeout} ||= 120;
    $obj->{port}    ||= 628;

    return $obj;
}

sub queueing
{
    my $self = shift;

    my $buff = _netstring($self->message);
    $buff   .= _netstring($self->sender);
    
    if( ref($self->recipients) eq 'ARRAY' ){
	$buff .= join("",map{_netstring($_)}@{$self->recipients});
    }else{
	$buff .= _netstring($self->recipients);
    }

    $buff = _netstring($buff);

    my $sock = IO::Socket::INET->new(PeerAddr => $self->host,
				     PeerPort => $self->port,
				     Proto    => 'tcp',
				     Timeout  => $self->timeout,
				     ) or die($@);

    $sock->autoflush(1);

    carp($buff) if $self->debug;
	
    print $sock $buff;

    my $res = join("",<$sock>);

    close($sock);

    return $res;
}

sub _netstring
{
    my $str = shift;
    return sprintf("%d:$str,",length($str));
}

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Net::QMQP - Quick Mail Queueing Protocol Client for qmail

=head1 SYNOPSIS

  use Net::QMQP;

  $qmqp = Net::QMQP->new(host => 'qmqpserver',Timeout => 60);

  $qmqp->sender('kobayasi@piano.gs');
  $qmqp->recipients('miyagawa@bulknews.net');
  $qmqp->message($mail_message);

  $qmqp->queueing();

=head1 WARNING

THIS IS ALPHA SOFTWARE AND NO TEST!

=head1 DESCRIPTION

The Net::QMQP module implements a client interface to the QMQP protocol.

=head1 METHODS

=over 4

=item new([ OPTIONS ])

This is the constructor for a new Net::QMQP object.

OPTIONS are passed in a hash like fashion, using key
and value pairs. Possible options are:

B<timeout> - Maximum time, in seconds, to wait for a 
response from the QMQP server (default: 120)

B<debug> - Enable debugging information (default: 0)

B<host> - The name of the remote host to which a QMQP
connection is required.(default: localhost)

B<port> - The using port.

B<sender> - The sender e-mail address

B<recipients> - The recipients' address(es). (array reference or scalar)

B<message> - The message body.

=item  queueing()

Queueing the mail to the QMQP server.

=item timeout(),sender(),debug(),host(),port(),sender(),recipients(),messsage()

There are accessors. Example:

 $obj->sender('kobayasi@piano.gs'); # sets the param.
 $obj->recipients([qw( kobayasi@piano.gs miyagawa@bulknews.net )]);

=head1 AUTHOR

Kobayasi Hiroyuki <kobayasi@piano.gs>

This library is free software; upi can redistribute it 
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

IO::Socket::INET

=cut
