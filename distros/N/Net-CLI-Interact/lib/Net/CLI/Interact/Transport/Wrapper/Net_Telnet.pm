package Net::CLI::Interact::Transport::Wrapper::Net_Telnet;
{ $Net::CLI::Interact::Transport::Wrapper::Net_Telnet::VERSION = '2.400000' }

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Str InstanceOf);

extends 'Net::CLI::Interact::Transport::Wrapper::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Wrapper::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Wrapper::Base::Options';
}

sub put { (shift)->wrapper->put( join '', @_ ) }

has '_buffer' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{''}),
);

sub buffer {
    my $self = shift;
    return $self->_buffer if scalar(@_) == 0;
    return $self->_buffer(shift);
}

sub pump {
    my $self = shift;

    # try to read all blocks of already available data first
    my $pump_buffer;
    my $available_content = '';
    while (defined $available_content) {
        $available_content = $self->wrapper->get(Errmode => 'return', Timeout => 0);
        if (defined $available_content) {
            $self->logger->log('transport', 'debug', 'read one block of data, appending to pump buffer');
            $pump_buffer .= $available_content;
        }
        else {
            $self->logger->log('transport', 'debug', 'no block of data available');
        }
    }

    # only try harder if no content was already available
    if (not defined $pump_buffer) {
        # this either returns data or throws an exception because of Net::Telnets default Errmode die
        my $content = $self->wrapper->get(Timeout => $self->timeout);
        if (defined $content) {
            $self->logger->log('transport', 'debug', 'read one block of data while waiting for timeout, appending to pump buffer');
            $pump_buffer .= $content;
        }
        else {
            $self->logger->log('transport', 'debug', 'no block of data available waiting for timeout');
        }
    }
    $self->_buffer($self->_buffer . $pump_buffer)
        if defined $pump_buffer;
}

has '+timeout' => (
    trigger => 1,
);

sub _trigger_timeout {
    my $self = shift;
    if (scalar @_) {
        my $timeout = shift;
        if ($self->connect_ready) {
            $self->wrapper->timeout($timeout);
        }
    }
}

has '+wrapper' => (
    isa => InstanceOf['Net::Telnet'],
);

around '_build_wrapper' => sub {
    my ($orig, $self) = (shift, shift);

    $self->logger->log('transport', 'notice', 'creating Net::Telnet wrapper for', $self->app);
    $self->$orig(@_);

    $SIG{CHLD} = 'IGNORE'
        if not $self->connect_options->reap;

    with 'Net::CLI::Interact::Transport::Role::ConnectCore';
    return $self->connect_core($self->app, $self->runtime_options);
};

after 'disconnect' => sub {
    delete $SIG{CHLD};
};

1;
