package Spike::Cache;

use strict;
use warnings;

use base qw(Spike::Object);

use Carp;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    return $class->SUPER::new(last_purge => time(), @_);
}

sub store {
    my ($self, $key) = splice @_, 0, 2;

    $self->purge;

    $self->{cache}{$key} = { ctime => $_ = time(), atime => $_, data => [ @_ ] };

    if ($self->debug) {
        carp(($self->name || "Cache").": record '$key' stored");
    }
}

sub get {
    my ($self, $key) = @_;

    $self->purge;

    my $cached = $self->{cache}{$key};
    return if !$cached;

    $cached->{atime} = time();

    return wantarray ? @{$cached->{data}} : $cached->{data}[0];
}

sub purge {
    my ($self, $force) = shift;

    my $time = time();

    if ($force || $time - $self->last_purge > $self->purge_time) {
        my @outdated = grep {
            my $v = $self->{cache}{$_};
            $time - $v->{ctime} > $self->max_ttl || $time - $v->{atime} > $self->max_idle_time
        } keys %{$self->{cache}};

        delete @{$self->{cache}}{@outdated} if @outdated;

        my @oversized = sort {
            $self->{cache}{$b}{atime} <=> $self->{cache}{$a}{atime}
        } keys %{$self->{cache}};

        splice @oversized, 0, $self->max_records;

        delete @{$self->{cache}}{@oversized} if @oversized;

        $self->last_purge(time());

        if ($self->debug) {
            carp(($self->name || "Cache").": ".(scalar @outdated + scalar @oversized)." records deleted");
        }
    }
}

__PACKAGE__->mk_accessors(qw(debug name max_records max_ttl max_idle_time purge_time last_purge));

1;
