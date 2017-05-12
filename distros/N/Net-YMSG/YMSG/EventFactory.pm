package Net::YMSG::EventFactory;
use strict;

use Net::YMSG;

use constant YMSG_LOGIN            => 1;
use constant YMSG_LOGOUT           => 2;
use constant YMSG_CHANGE_STATE     => 3;
use constant YMSG_CHANGE_AVAILABLE => 4;
use constant YMSG_MESSAGE          => 6;
use constant YMSG_NEW_FRIEND_ALERT => 15;
use constant YMSG_SERVER_IS_ALIVE  => 76;
use constant YMSG_AUTH             => 84;
use constant YMSG_BUDDY_LIST       => 85;
use constant YMSG_BEGIN_AUTH       => 87;

use constant ID                       => '1';
use constant BADDY_NAME               => '7';
use constant NUMBER_OF_ONLINE_BADDY   => '8';
use constant STATE                    => '10';
use constant SESSION_ID               => '11';
use constant ONLINE_OR_OFFLINE        => '13';
use constant STATE_OF_USER_DEFINITION => '19';
use constant BUSYNESS                 => '47';


use constant EVENT_CLASS => {
	1  => 'Net::YMSG::GoesOnline',
	2  => 'Net::YMSG::GoesOffline',
	3  => 'Net::YMSG::ChangeState',
	4  => 'Net::YMSG::ChangeState',
	6  => 'Net::YMSG::ReceiveMessage',
	15 => 'Net::YMSG::NewFriendAlert',
	76 => 'Net::YMSG::ServerIsAlive',
	85 => 'Net::YMSG::ReceiveBuddyList',
	87 => 'Net::YMSG::ChallengeStart',
	152 => 'Net::YMSG::ChatRoomLogon',
	168 => 'Net::YMSG::ChatRoomReceive',
	155 => 'Net::YMSG::ChatRoomLogoff',
};



sub new
{
	my $class = shift;
	my $connection = shift;
	bless { connection => $connection }, $class;
}


sub create_by_raw_data
{
	my $self = shift;
	my $connection = $self->{connection};
	my ($event_code, $identifier, $body) = eval {$self->_get_message_body;};
	if ($@) {
		# print STDERR $@;
		require Net::YMSG::InvalidLogin;
		return Net::YMSG::InvalidLogin->new($connection);
	}

	my ($code, $recipient, $private, $sender,
		@baddy) = split /\xC0\x80/, $body;
	if ($event_code == YMSG_LOGIN && lc $recipient eq lc $sender) {
		require Net::YMSG::Login;
		my $event = Net::YMSG::Login->new($connection);
		$event->source($body);
		$event->from($sender);
		$connection->identifier($identifier);
		return $event if scalar $connection->buddy_list <= 0;

		shift @baddy;
		my $id = shift @baddy;
		my $buddy;
		for (my $i=0; $i < scalar @baddy; $i+=2) {
			if ($baddy[$i] eq BADDY_NAME) {
				$buddy = $connection->get_buddy_by_name($baddy[$i+1]);
			}
			elsif ($baddy[$i] eq STATE) {
				$buddy->status($baddy[$i+1]);
			}
			elsif ($baddy[$i] eq STATE_OF_USER_DEFINITION) {
				$buddy->custom_status($baddy[$i+1]);
			}
			elsif ($baddy[$i] eq BUSYNESS) {
				$buddy->busy($baddy[$i+1]);
			}
			elsif ($baddy[$i] eq SESSION_ID) {
				$buddy->session_id($baddy[$i+1]);
			}
			elsif ($baddy[$i] eq ONLINE_OR_OFFLINE) {
				$buddy->online($baddy[$i+1]);
			}
			else {}
		}
		return $event;

	} else {
		my $class = EVENT_CLASS->{$event_code} || 'Net::YMSG::DummyEvent';
		eval "require $class";
	#	print STDERR "Calling up class: $class with $body\n";
		if ($@) {
		#	print STDERR $@;
			require Net::YMSG::UnImplementEvent;
			my $event = Net::YMSG::UnImplementEvent->new($connection);
			$event->code($event_code);
			$event->source($body);
			return $event;
		}
		my $event = $class->new($connection);
		$event->source($body);
		return $event;
	}
}


sub create_by_name
{
	my $self = shift;
	my $class = 'Net::YMSG::'. shift;
	eval "require $class";
	if ($@) {
		require Net::YMSG::NullEvent;
		return Net::YMSG::NullEvent->new;
	}
	return $class->new($self->{connection});
}


sub _get_message_body
{
	my $self = shift;
	my $handle = $self->{connection}->handle;
	my %command;

	my $header = $self->_recv_by_length(20);
	my (
		$signature,
		$version,
		$length,
		$event_code,
		$return,
		$identifier
	) = unpack "a4Cx3nnNN", $header;

	die 'Wring protocol' if $signature ne Net::YMSG->YMSG_STD_HEADER;
	my $message = $self->_recv_by_length($length);
	return ($event_code, $identifier, $message);

}


sub _recv_by_length
{
	my $self = shift;
	my $length = shift || 0;
	my $handle = $self->{connection}->handle;
	my $message = '';

	while (length $message < $length) {
		my $buff = '';
		$handle->sysread($buff, 1, 0)
			or die "Disconnect socket";
		$message .= $buff;
	}
	if (0) {
		print "\n";
		print map {
			sprintf "%s  ", $_ =~ /[\w\d]/ ? $_ : '.';
		} split //, $message;
		print "\n";
		print map {
			sprintf "%02x ", ord $_;
		} split //, $message;
	}
	return $message;
}
1;
__END__
