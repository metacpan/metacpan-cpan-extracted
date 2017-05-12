package POE::Filter::YahooMessengerPacket;
use strict;
use POE::Component::YahooMessenger::Constants;
use POE::Component::YahooMessenger::Event;

sub new {
    my $class = shift;
    bless {
	buffer      => '',
	get_state   => 'header',
	body_info   => {},
	identifier  => undef,
    }, $class;
}

use constant DEBUG => 0;
sub Dumper { require Data::Dumper; Data::Dumper::Dumper(@_) }

sub get {
    my($self, $stream) = @_;
    $self->{buffer} .= join '', @$stream;

    if ($self->{get_state} eq 'header') {
	# not enough header bytes
	return [] if length($self->{buffer}) < 20;

	my $header = substr $self->{buffer}, 0, 20, '';
	my($signature, $version, $length, $event_code, $option, $identifier)
	    = unpack "a4Cx3nnNN", $header;
	if ($signature ne $MessageHeader) {
	    _carp("signateure mismatch: $signature");
	    return [];
	}
	$self->{identifier} ||= $identifier;

	# switch to body mode
	$self->{get_state} = 'body';
	$self->{body_info} = {
	    length     => $length,
	    event_code => $event_code,
	    identifier => $identifier,
	};
    }

    # not enough body bytes
    return [] if length($self->{buffer}) < $self->{body_info}->{length};

    # we have enough body bytes
    my $body = substr $self->{buffer}, 0, $self->{body_info}->{length}, '';
    $self->{get_state} = 'header';

    my $event = POE::Component::YahooMessenger::Event->new_from_body(
	$self->{body_info}->{event_code}, $body,
    );
    DEBUG and warn("GET: ", Dumper($event));
    return [ $event ];
}

sub put {
    my($self, $events) = @_;
    return [ map $self->_put($_), @$events ];
}

sub _put {
    my($self, $event) = @_;
    DEBUG and warn("PUT: ", Dumper($event));
    my $body = $event->body;
    my $header = pack(
	"a4Cx3nnNN",
	$MessageHeader, 9, length($body), $event->code, $event->option, $self->{identifier} || 0,
    );
    return $header. $body;
}

1;
