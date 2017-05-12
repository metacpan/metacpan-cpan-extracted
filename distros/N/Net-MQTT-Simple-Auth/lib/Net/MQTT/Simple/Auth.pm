package Net::MQTT::Simple::Auth;

use parent 'Net::MQTT::Simple';

our $VERSION = '0.001';

sub new {
	my ($class, $server, $user, $password, $sockopts) = @_;
	# @_ == 2 or @_ == 3 or _croak "Wrong number of arguments for $class->new";

	my $self = $class->SUPER::new ($server, $sockopts);

	$self->{mqtt_user} = $user;
	$self->{mqtt_password} = $password;

	return $self;
}

sub _send_connect {
	my ($self) = @_;

	$self->_send("\x10" . Net::MQTT::Simple::_prepend_variable_length( pack (
		"x C/a* C C n n/a* n/a* n/a*",
		$Net::MQTT::Simple::PROTOCOL_NAME,
		0x03,
		0xC2,
		$Net::MQTT::Simple::KEEPALIVE_INTERVAL,
		$self->_client_identifier,
		$self->{mqtt_user},
		$self->{mqtt_password}
	)));
}


1;

__END__

=head1 NAME

Net::MQTT::Simple::Auth - Enables User/Password Authentication to L<Net::MQTT::Simple> Client

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Object oriented (extends Net::MQTT::Simple)

    use Net::MQTT::Simple::Auth;

    my $mqtt = Net::MQTT::Simple::Auth->new("mosquitto.example.org:1883", "user", "password" [, $socket_opts]);

    # Refers to L<Net::MQTT::Simple>

    $mqtt->publish("topic/here" => "Message here");
    $mqtt->retain( "topic/here" => "Message here");

    $mqtt->run(
        "sensors/+/temperature" => sub {
            my ($topic, $message) = @_;
            die "The building's on fire" if $message > 150;
        },
        "#" => sub {
            my ($topic, $message) = @_;
            print "[$topic] $message\n";
        },
    }

=head1 DESCRIPTION

Adds login authentication via username and password to the very helpful and easy to use L<Net::MQTT::Simple> Client

=head1 LICENSE

Same as it's parent: Pick your favourite OSI approved license :)

http://www.opensource.org/licenses/alphabetical

=head1 AUTHOR

Manuel Krenzke

=head1 SEE ALSO

L<Net::MQTT::Simple>
