package SpamMonkey::Utils;
use strict;
my %cache;
use POSIX qw(SIGALRM);

sub host_to_ip { # Basic method
    my ($self, $host) = @_;
    my $addr;
    return $cache{$host} if exists $cache{$host};
    $addr = eval {
       POSIX::sigaction(SIGALRM, POSIX::SigAction->new(sub { die "alarm" }));
       alarm 5;
       (gethostbyname $host)[4];
    };
    alarm 0;
    $cache{$host} = $addr; # Yes, this caches failures
    return unless $addr;
    my @bits = unpack("C4",$addr);
    return wantarray ? @bits : join ".", @bits;
}

sub rbl_check { # Complex method
    my ($self, $host, $type, $timeout) = @_;
    my $resolver = Net::DNS::Resolver->new();
    $resolver->tcp_timeout($timeout) if $timeout;
    $resolver->udp_timeout($timeout) if $timeout;
    return ! ! $resolver->query($host, $type);
}


1;
