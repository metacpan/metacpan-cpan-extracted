package Reddit::Client::ModmailConversation;
use strict;
use warnings; 
use Carp;

require Reddit::Client::Thing; 
use base qw/Reddit::Client::Thing/; # base doesn't require. use parent does

# what will happpen if we use Thing as a parent but don't use fields here? Proly
# those fields cause errs.  # Just use them, no sense fucking with it now
# id
use fields qw/
authors
isAuto
isHighlighted
isInternal
isRepliable
lastModUpdate
lastUnread
lastUpdated
lastUserUpdate
numMessages
objIds
owner
participant
state
subject

messages
modActions
/;

# no type, apparently. None listed in docs. Message is t4, but no indication
# these are Messages
sub new {
	my ($class, $reddit, $conversation, $messages, $modActions) = @_;
	my $data = $conversation;
	if (ref $data eq 'HASH') {
		# if we put messages here, we have to use fuckery to make it come after
		# isObj, because that must exist first. might as well just call our
		# thing after.
		#$data->{messages} = $messages if $messages;
		$data->{modActions} = $modActions if $modActions;
	} else {
		die "Expected a hash reference for arg 2\n";
	}
	my $this = $class->SUPER::new($reddit, $data);
	$this->set_messages($messages) if $messages;

	return $this;
}

# Expects hash reference containing hash references of arbitrary keys
# (keys are message IDs)
sub set_messages {
	my ($this, $msgdat) = @_;

	# this should create an array of ModmailMessages out of $messages using the
	# order in objIds. objIds must be set first

	my $messages = [];

	if (ref $this->{objIds} eq 'ARRAY' and ref $msgdat eq 'HASH') {
		for my $o ( @{$this->{objIds}})  {
			if ($o->{key} eq 'messages') {
				push @$messages, new Reddit::Client::ModmailMessage( $this->{session}, $msgdat->{$o->{id}} );
			}
		}
		$this->{messages} = $messages;
	}

}

sub archive {
	my $this = shift;
	return $this->{session}->modmail_action('archive', $this->{id});
}

