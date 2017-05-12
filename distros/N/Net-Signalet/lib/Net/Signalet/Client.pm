package Net::Signalet::Client;
use strict;
use warnings;

use parent qw(Net::Signalet);

use Carp();

sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 && ref($args[0]) eq 'HASH' ? %{$args[0]} : @args;

    $class->SUPER::_init(%args);

    my $sock = IO::Socket::INET->new(
        Proto     => 'tcp',
        PeerAddr  => $args{daddr},
        PeerPort  => $args{dport}   || 14550,
        LocalAddr => $args{saddr}   || undef,
        LocalPort => $args{sport}   || undef,
        Timeout   => $args{timeout} || 5,
    ) or Carp::croak "Can't connect to server: $!";

    my $self = bless {
        worker_pid => undef,
        sock       => $sock
    }, $class;
    return $self;
}


sub run {
    my ($self, %params) = @_;

    if (!exists $params{command} && !exists $params{code}) {
        Carp::croak "Required command or code";
    }
    if (my $command = $params{command}) {
        my $command = join ' ', @{$params{command}} if ref($params{command}) eq 'ARRAY';
        system($command);
    }
    elsif ($params{code}) {
        my $pid = fork;
        unless ($pid) {
            # child process
            $params{code}->();
        }
        $self->{worker_pid} = $pid if $pid > 0;
    }
}

1;
