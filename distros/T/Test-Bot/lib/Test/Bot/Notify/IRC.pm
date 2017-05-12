package Test::Bot::Notify::IRC;

use Any::Moose;
with 'Test::Bot::Notify';

use AnyEvent;
use AnyEvent::IRC::Client;

has 'irc_host' => (
    is => 'rw',
    isa => 'Str',
);

has 'irc_port' => (
    is => 'rw',
    isa => 'Int',
    default => 6667,
);

has 'irc_channel' => (
    is => 'rw',
    isa => 'Str',
    default => '#db',
    required => 1,
);

has 'irc_nick' => (
    is => 'rw',
    isa => 'Str',
    default => 'test_bot',
);

has '_irc_client' => (
    is => 'rw',
    isa => 'AnyEvent::IRC::Client',
    clearer => 'clear_irc_client',
);

has '_connected' => ( is => 'rw', isa => 'Bool' );

after 'setup' => sub {
    my ($self) = @_;

    die "irc_host is required" unless $self->irc_host;
    die "irc_channel is required" unless $self->irc_channel;
};

after notify => sub {
    my ($self, @commits) = @_;

    my $client = $self->_irc_client && $self->_connected ?
        $self->_irc_client : AnyEvent::IRC::Client->new;

    my $send_notification = sub {
        foreach my $commit (@commits) {
            my $msg = $self->format_commit($commit) or next;

            $client->send_long_message('utf-8', 0, PRIVMSG => $self->irc_channel, $msg);
            $client->reg_cb(buffer_empty => sub {
                $client->disconnect;
            });
        }
    };
    
    unless ($self->_connected) {
        $client->reg_cb(
            connect => sub {
                my ($con, $err) = @_;
                if (defined $err) {
                    warn "IRC connect error: $err\n";
                    return;
                }
                $self->_connected(1);
            },

            error => sub {
                my ($con, $code, $message, $ircmsg) = @_;
                warn "IRC error $code $message: $ircmsg\n";
                $con->disconnect;
            },
            
            disconnect => sub {
                $self->_connected(0);
                $self->clear_irc_client;
                #undef $client;
            },
        
            registered => sub {
                my ($con) = @_;
            
                # connected and ready to go
                $send_notification->();
            },
        );

        $self->_irc_client($client);
        $client->connect($self->irc_host, $self->irc_port, { nick => $self->irc_nick });
    }
};

sub format_commit {
    my ($self, $commit) = @_;

    my $status = $commit->test_success ? "\033[32mPASS\033[0m" : "\033[31mFAIL\033[0m";
    my $id = substr($commit->id, 0, 6);
    my $author = $commit->author || 'unknown';
    my $msg = $commit->message;

    my $output = $commit->test_output;

    my $ret = "$author: $id ($msg) status: $status";
    $ret .= "\n$output" if $output;

    return $ret;
}

1;
