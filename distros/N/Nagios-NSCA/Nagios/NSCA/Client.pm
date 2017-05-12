package Nagios::NSCA::Client;
use strict;
use warnings;
use Nagios::NSCA::Client::Settings;
use Nagios::NSCA::Client::Server;
use Nagios::NSCA::Client::InputFilter;
use base 'Nagios::NSCA::Base';

our $VERSION = sprintf("%d", q$Id: Client.pm,v 1.2 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);

sub new {
    my ($class, %args) = @_;
    my $settings = Nagios::NSCA::Client::Settings->new(%args);
    my $fields = {
        filter => Nagios::NSCA::Client::InputFilter->new(),
        timeout => $settings->timeout,
        server => undef,
        input => \*STDIN,
        output => \*STDOUT,
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    return $self;
}

sub run {
    my ($self, %args) = @_;

    # Allow run() to be called as a class method.  In arguments are given then
    # force running it as a class method.
    if (not ref($self) or %args) {
        $self = __PACKAGE__->new(%args);
    }

    # Start server, then initialize the filter w/ the timestamp
    $self->runServer();

    # Sit in a loop processing input, convert it to packets, send to server.
    while (my $line = $self->getInput) {
        my $packet = $self->filter->line2packet($line) || next;
        $self->server->sendPacket($packet) || last;
    }

    # Print a diagnostic to the given output FH, if present.
    print($self->output, $self->server->numPacketSent .  " data packet(s) " . 
          "sent to host successfully.\n") if $self->output;
}

sub runServer {
    my $self = shift;
    my $server = Nagios::NSCA::Client::Server->new();
    $server->connect();
    $self->server($server);
}

sub getInput {
    my $self = shift;

    # Install an alarm handler for timeouts.
    local $SIG{ALRM} = sub {
        die "Error: Timeout after " . $self->timeout . " seconds.\n";
    };

    my $input = $self->input;
    alarm $self->timeout;
    my $line = <$input>;
    alarm 0;

    return $line;
}

1;
