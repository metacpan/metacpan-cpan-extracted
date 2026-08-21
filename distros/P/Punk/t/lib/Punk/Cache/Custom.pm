package Punk::Cache::Custom;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.24';

use constant OVERHEAD => 64;    # what an entry costs beyond key and value

# Per-process, so Punk::Cache invalidates across the pool on its behalf.
sub is_shared { 0 }

sub new {
    my ($class, %opt) = @_;
    return bless {
        h         => {},
        used      => {},
        seq       => 0,
        bytes     => 0,
        max_bytes => $opt{max_bytes} || 8 * 1024 * 1024,
        hits      => 0,
        misses    => 0,
        evictions => 0,
        refused   => 0,
        expired   => 0,
    }, $class;
}

sub get {
    my ($self, $key) = @_;
    my $e = $self->{h}{$key};

    if (!$e) {
        $self->{misses}++;
        return undef;
    }
    if ($e->[1] && $e->[1] <= time) {
        $self->{expired}++;
        $self->{misses}++;
        $self->_drop($key);
        return undef;
    }

    $self->{hits}++;
    $self->{used}{$key} = ++$self->{seq};
    return $e->[0];
}

sub set {
    my ($self, $key, $value, $ttl) = @_;
    $value = '' unless defined $value;
    my $cost = length($key) + length($value) + OVERHEAD;

    # Refused, not stored - making room for it would evict everything else
    # and still not fit.
    if ($cost > $self->{max_bytes}) {
        $self->{refused}++;
        return 0;
    }

    $self->_drop($key) if exists $self->{h}{$key};
    $self->{h}{$key}    = [ $value, ($ttl ? time + $ttl : 0), $cost ];
    $self->{used}{$key} = ++$self->{seq};
    $self->{bytes}     += $cost;

    while ($self->{bytes} > $self->{max_bytes}) {
        my ($coldest) = sort { $self->{used}{$a} <=> $self->{used}{$b} }
                        keys %{ $self->{used} };
        last unless defined $coldest;
        $self->_drop($coldest);
        $self->{evictions}++;
    }

    return 1;
}

sub delete {
    my ($self, $key) = @_;
    return 0 unless exists $self->{h}{$key};
    $self->_drop($key);
    return 1;
}

sub clear {
    my ($self) = @_;
    $self->{h}     = {};
    $self->{used}  = {};
    $self->{bytes} = 0;
    return 1;
}

sub stats {
    my ($self) = @_;
    return (
        hits      => $self->{hits},
        misses    => $self->{misses},
        evictions => $self->{evictions},
        refused   => $self->{refused},
        expired   => $self->{expired},
        bytes     => $self->{bytes},
        entries   => scalar keys %{ $self->{h} },
        max_bytes => $self->{max_bytes},
    );
}

sub _drop {
    my ($self, $key) = @_;
    my $e = delete $self->{h}{$key} or return;
    delete $self->{used}{$key};
    $self->{bytes} -= $e->[2];
    return;
}

1;
