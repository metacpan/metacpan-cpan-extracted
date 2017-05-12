package Parallel::MapReduce::Worker::FakeRemote;

use base Parallel::MapReduce::Worker;

use Data::Dumper;

sub new {
    my $class = shift;
    my %opts = @_;
    my $self = bless { %opts }, $class;
    return $self;
}

my $comm; # only a buffer for the fake stuff

sub map {
    my $self = shift;
    $comm = \@_;
    fake_remoted_map();
    return $comm;
}

sub fake_remoted_map {
    my ($chunks, $slice, $servers, $job) = @{ $comm };
    my $w  = new Parallel::MapReduce::Worker;
    my $cs = $w->map ($chunks, $slice, $servers, $job);
    $comm = $cs;
}


sub reduce {
    my $self = shift;
    my $ks = shift;
    my $ss = shift;
    my $jj = shift;
#warn "master writes to reduce ".Dumper ($ks, $ss, $jj);
    $comm = [ $ks, $ss, $jj ];
    fake_remoted_reduce();
    return $comm;
}

sub fake_remoted_reduce {
    my $self = shift;
    my ($keys, $servers, $job) = @{ $comm };
    my $w  = new Parallel::MapReduce::Worker;
    my $cs = $w->reduce ($keys, $servers, $job);
    $comm = $cs;
}

our $VERSION = 0.03;

1;
