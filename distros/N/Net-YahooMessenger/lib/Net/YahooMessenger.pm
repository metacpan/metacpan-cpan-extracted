package Net::YahooMessenger;

=head1 NAME

Net::YahooMessenger - Interface to the Yahoo!Messenger IM protocol

=head1 SYNOPSIS

	use Net::YahooMessenger;

	my $yahoo = Net::YahooMessenger->new(
		id       => 'your_yahoo_id',
		password => 'your_password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";
	$yahoo->send('recipient_yahoo_id', 'Hello World!');

=head1 CAVEATS

Module was changed to work with the latest version(16) of the Yahoo protocol. However, this might not work very well, your opinions and suggestions will be helpfull.

=head1 DESCRIPTION

Net::YahooMessenger is a client class for connecting with the Yahoo!Messenger server, and transmitting and receiving a message.

Since implement of a protocol is the result of analyzing and investigating a packet, it has an inadequate place. However, it is working as expected usually.

=cut

use Carp;
use IO::Socket;
use IO::Select;
use Net::YahooMessenger::Buddy;
use Net::YahooMessenger::CRAM;
use Net::YahooMessenger::HTTPS;

use constant YMSG_STD_HEADER       => 'YMSG';
use constant YMSG_SEPARATER        => "\xC0\x80";
use constant YMSG_SALT             => '_2S43d5f';
use constant YMSG_PROTOCOL_VERSION => '16';

use strict;

use vars qw($VERSION);
$VERSION = '0.19';

=head1 METHODS

This section documents method of the Net::YahooMessenger class.

=head2 Net::YahooMessenger->new()

It should be called with following arguments (items with default value are optional):

	id            => yahoo id
	password      => password
	hostname      => server hostname
	                 (default 'cs.yahoo.com)

Returns a blessed instantiation of Net::YahooMessenger.

Note: If you plan to connect with Yahoo!Japan(yahoo.co.jp), it sets up as follows.

	my $yahoo_japan = Net::YahooMessenger->new(
		hostname      => 'cs.yahoo.co.jp',
	);

I<Since it connects with Yahoo!(yahoo.com), this procedure is unnecessary in almost all countries.>

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    bless {
        id       => $args{id},
        password => $args{password},
        hostname => $args{hostname} || 'scsa.msg.yahoo.com',

        #this is probably not needed for the version 16 YM protocol
        pre_login_url => $args{pre_login_url}
          || 'http://msg.edit.yahoo.com/config/',
        handle        => undef,
        _read         => IO::Select->new,
        _write        => IO::Select->new,
        _error        => IO::Select->new,
        event_handler => undef,
        buddy_list    => [],
    }, $class;
}

=head2 $yahoo->id([$yahoo_id])

This method gets or sets the present B<Yahoo Id>.

=cut

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    $self->{id};
}

=head2 $yahoo->password([$password])

This method gets or sets the present B<password>.

=cut

sub password {
    my $self = shift;
    $self->{password} = shift if @_;
    $self->{password};
}

=head2 $yahoo->login()

Call this after C<new()> to logon the Yahoo!Messenger service.

=cut

sub login {
    my $self = shift;

    my $server = $self->get_connection;

    my $msg = $self->_create_message( 87, 0, '1' => $self->id, );
    $server->send( $msg, 0 );
    my $event = $self->recv();
    my $https = Net::YahooMessenger::HTTPS->new( $self->id, $self->password,
        $event->body );
    my $auth = $self->_create_message(
        84, 0,
        '1'   => $self->id,
        '0'   => $self->id,
        '277' => $https->y_string,
        '278' => $https->t_string,
        '307' => $https->md5_string,
        '244' => '4194239',
        '2'   => $self->id,
        '2'   => $self->id,
        '135' => '9.0.0.2152',
    );
    $server->send($auth);
    my $user_info  = $self->recv();
    my $buddy_list = $self->recv();

    my $login   = $self->recv();
    my $handler = $self->get_event_handler();
    $handler->accept($login) if $handler;

    $self->add_event_source(
        $server,
        sub {
            my $event   = $self->recv;
            my $handler = $self->get_event_handler;
            $handler->accept($event);
        },
        'r'
    );

    return $login->is_enable();
}

sub _dump_packet {
    my $source = shift;
    print join ' ',
      map { sprintf '%02x(%s)', ord $_, (/^[\w\-_]$/) ? $_ : '.'; } split //,
      $source;
    print "\n";
}

=head2 $yahoo->send($yahoo_id, $message)

This method send an Instant-Message C<$message> to the user specified by C<$yahoo_id>. A kanji code is Shift_JIS when including Japanese in $message.

=cut

sub send {
    my $self      = shift;
    my $recipient = shift;
    my $message   = join '', @_;
    my $server    = $self->handle;

    my $event = $self->create('SendMessage');
    $event->from( $self->id );
    $event->to($recipient);
    $event->body($message);
    $event->option(1515563606);  # in Buddy list then 1515563606 else 1515563605
    $server->send( $event->to_raw_string, 0 );
}

=head2 $yahoo->change_state($busy, $status_message)

This method sets the I<status messages> for the current user. 'Status message' is set by C<$status_message>. 'Busy icon' is set by the numerical value of C<$busy>.

The C<$busy> should be called with following arguments:

	0 - I'm Available
	1 - Busy
	2 - Sleep

=cut

sub change_state {
    my $self    = shift;
    my $busy    = shift;
    my $message = join '', @_;
    my $server  = $self->handle;

    my $event = $self->create('ChangeState');
    $event->status_code(99);    # 99 : Custom status
    $event->busy($busy);
    $event->body($message);

    $server->send( $event->to_raw_string, 0 );
}

sub change_status_by_code {
    my $self        = shift;
    my $status_code = shift || 0;
    my $server      = $self->handle;

    my $event = $self->create('ChangeState');
    $event->status_code($status_code);
    $event->busy(1);

    $server->send( $event->to_raw_string, 0 );
}

sub ping {
    my $self    = shift;
    my $server  = $self->get_connection;
    my $command = $self->_create_message( 76, 0, 0, '' );
    $server->send( $command, 0 );
    my $pong = $self->recv();
    return $pong->is_enable;
}

=head2 $yahoo->recv()

This method reads the message from a server socket and returns a corresponding B<Event object>.
The B<Event object> which will be returned is as follows:

	Net::YahooMessenger::InvalidLogin     - Invalid Login
	Net::YahooMessenger::Login            - Succeeded in Login.
	Net::YahooMessenger::GoesOnline       - Buddy has logged in.
	Net::YahooMessenger::ReceiveMessage   - Message was received.
	Net::YahooMessenger::ChangeState      - Buddy has change status.
	Net::YahooMessenger::GoesOffline      - Buddy logged out.
	Net::YahooMessenger::NewFriendAlert   - New Friend Alert.
	Net::YahooMessenger::UnImplementEvent - Un-implemented event was received.

All event objects have the following attributes:

=over 4

=item $event->from

B<Yahoo id> which invoked the event.

=item $event->to

B<Yahoo id> which should receive an event.

=item $event->body

The contents of an event. The message and state which were transmitted.

=item $event->code

The event number on Yahoo Messenger Protocol.

=back

=cut

sub recv {
    my $self = shift;
    require Net::YahooMessenger::EventFactory;
    my $event_factory = Net::YahooMessenger::EventFactory->new($self);
    return $event_factory->create_by_raw_data();
}

=head2 $yahoo->get_connection()

This method returns a raw server socket. When connection has already ended, the socket is returned, and when not connecting, it connects newly.

=cut

sub get_connection {
    my $self = shift;
    return $self->handle if $self->handle;

    my $server = IO::Socket::INET->new(
        PeerAddr => $self->{hostname},
        PeerPort => $self->get_port,
        Proto    => 'tcp',
        Timeout  => 30,
    ) or die $!;
    $server->autoflush(1);
    return $self->handle($server);
}

sub buddy_list {
    my $self = shift;
    @{ $self->{buddy_list} } = @_ if @_;
    return @{ $self->{buddy_list} };
}

sub get_buddy_by_name {
    my $self = shift;
    my $name = shift;
    my ($buddy) = grep { lc $_->name eq lc $name } $self->buddy_list;
    return $buddy;
}

=head2 $yahoo->set_event_hander($event_handler)

This method sets the Event handler for a specific Yahoo!Messenger server event. C<$event_handler> is the sub class of Net::YahooMessenger::EventHandler.

Note: The event which can be overwritten should look at the method signature of L<Net::YahooMessenger::EventHandler>.

=cut

sub set_event_handler {
    my $self = shift;
    $self->{event_handler} = shift;
}

sub get_event_handler {
    my $self = shift;
    return $self->{event_handler};
}

=head2 $yahoo->add_event_source($file_handle, $code_ref, $flag)

This method adds the file handle (event sauce) to supervise. The file handle to add is specified by C<$file_handle>. The code reference to the processing to perform is specified by $code_ref. 

	C<$flag> eq 'r' - set when the file handle to add is an object for read.
	C<$flag> eq 'w' - set when the file handle to add is an object for write.

By adding another handle (for example, STDIN), processing can be performed based on those inputs. Usually, the server socket of 'Yahoo!Messenger server' is set as a candidate for surveillance.

	ex:
		# The input of STDIN is transmitted to 'EXAMPLE_YAHOO_ID'.
		$yahoo->add_event_source(\*STDIN, sub {
			my $message = scalar <STDIN>;
			chomp $message;
			$yahoo->send('EXAMPLE_YAHOO_ID', $message);
		}, 'r');

=cut

sub add_event_source {
    my $self = shift;
    my ( $handle, $code, $flag, $obj ) = @_;

    foreach my $mode ( split //, lc $flag ) {
        if ( $mode eq 'r' ) {
            $self->{_read}->add($handle);
        }
        elsif ( $mode eq 'w' ) {
            $self->{_write}->add($handle);
        }
    }
    $self->{_connhash}->{$handle} = [ $code, $obj ];
}

=head2 $yahoo->start()

If you're writing a fairly simple application that doesn't need to interface with other event-loop-based libraries, you can just call start() to begin communicating with the server.

=cut

sub start {
    my $self = shift;
    while (1) {
        $self->do_one_loop;
    }
}

sub do_one_loop {
    my $self = shift;

    for my $ready (
        IO::Select->select(
            $self->{_read}, $self->{_write}, $self->{_error}, 10
        )
      )
    {
        for my $handle (@$ready) {
            my $event = $self->{_connhash}->{$handle};
            $event->[0]->( $event->[1] ? ( $event->[1], $handle ) : $handle );
        }
    }
}

sub get_port {
    my $self = shift;
    return $self->{port} if $self->{port};
    return 5050;
}

sub _create_message {
    my $self       = shift;
    my $event_code = shift;
    my $option     = shift;
    my @param      = @_;
    my $body       = '';

    while (@param) {
        my $key   = shift @param;
        my $value = shift @param;
        $body .= $key . YMSG_SEPARATER . $value . YMSG_SEPARATER;
    }

    my $header = pack "a4xCx2nnNN",
      YMSG_STD_HEADER,
      YMSG_PROTOCOL_VERSION,
      length $body,
      $event_code,
      $option,
      $self->identifier || 0;
    return $header . $body;
}

sub create {
    my $self       = shift;
    my $event_name = shift;

    require Net::YahooMessenger::EventFactory;
    my $event_factory = Net::YahooMessenger::EventFactory->new($self);
    return $event_factory->create_by_name($event_name);
}

sub _create_login_command {
    my $self  = shift;
    my $event = $self->create('Login');
    $event->id( $self->id );
    $event->password( $self->password );
    $event->from( $self->id );
    $event->hide(0);
    return $event->to_raw_string;
}

sub handle {
    my $self = shift;
    $self->{handle} = shift if @_;
    $self->{handle};
}

sub identifier {
    my $self = shift;
    $self->{identifier} = shift if @_;
    $self->{identifier};
}

#

#	my @buddy = $self->_get_buddy_list_by_array(
#		$self->_get_list_by_name('BUDDYLIST', $response->content)
#	);
#	$self->buddy_list(@buddy);

sub _get_list_by_name {
    my $self   = shift;
    my $name   = shift;
    my $string = shift;

    if ( $string =~ /BEGIN $name\r?\n(.*)\r?\nEND $name/s ) {
        my @list = split /\r?\n/, $1;
        return @list;
    }
}

sub add_buddy_by_name {
    my $self       = shift;
    my $group      = shift;
    my @buddy_name = @_;
    my @buddy_list = $self->buddy_list();
    for my $name (@buddy_name) {
        my $buddy = Net::YahooMessenger::Buddy->new;
        $buddy->name($name);
        push @buddy_list, $buddy;
    }
    $self->buddy_list(@buddy_list);
}

1;
__END__

=head1 EXAMPLE

=head2 Send message

	#!perl
	use Net::YahooMessenger;
	use strict;

	my $yahoo = Net::YahooMessenger->new;
	$yahoo->id('yahoo_id');
	$yahoo->password('password');
	$yahoo->login or die "Can't login Yahoo!Messenger";

	$yahoo->send('recipient_yahoo_id', 'Hello World!');
	__END__

=head2 Change Status message

	#!perl
	use Net::YahooMessenger;
	use strict;
	use constant IN_BUSY => 1;

	my $yahoo = Net::YahooMessenger->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->login or die "Can't login Yahoo!Messenger";;

	$yahoo->change_state(IN_BUSY, q{I'm very busy now!});
	sleep 5;
	__END__

=head2 Received message output to STDOUT

	#!perl
	use Net::YahooMessenger;
	use strict;

	my $yahoo = Net::YahooMessenger->new(
		id       => 'yahoo_id',
		password => 'password',
	);
	$yahoo->set_event_handler(new ToStdoutEventHandler);
	$yahoo->login or die "Can't login Yahoo!Messenger";
	$yahoo->start;



	package ToStdoutEventHandler;
	use base 'Net::YahooMessenger::EventHandler';
	use strict;

	sub ChangeState {}
	sub GoesOffline {}
	sub GoesOnline {}
	sub UnImplementEvent {}

	sub ReceiveMessage
	{
		my $self = shift;
		my $event = shift;
		printf "%s: %s\n", $event->from, $event->body;
	}
	__END__

=head2 Connect to Yahoo!Japan Messege server

	#!perl
	use Net::YahooMessenger;
	use strict;

	my $yahoo = Net::YahooMessenger->new(
		pre_login_url => 'http://edit.my.yahoo.co.jp/config/',
		hostname      => 'cs.yahoo.co.jp',
	);
	$yahoo->id('yahoo_id');
	$yahoo->password('password');
	$yahoo->login or die "Can't login Yahoo!Messenger";

	$yahoo->send('recipient_yahoo_id', 'Konnitiwa Sekai!');
	__END__

=head1 AUTHOR

Hiroyuki OYAMA <oyama@cpan.org> http://ymca.infoware.ne.jp/

From October 2003, this module is taken over and maintained by
Tatsuhiko Miyagawa L<lt>miyagawa@bulknews.netL<gt>

From September 2009, Emil Dragu <emil.dragu@webwave.ro> is comaintainer.

=head1 SEE ALSO

<http://messenger.yahoo.co.jp/>, <http://ymca.infoware.ne.jp/>

=head1 COPYRIGHT

Copyright (C) 2001 Hiroyuki OYAMA. Japan. All righits reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itsefl.

Please refer to the use agreement of Yahoo! about use of the Yahoo!Messenger service.

=cut
