package ShardedKV::Storage::ReplicatedRest;

use ShardedKV::Storage::Rest;

use strict;
use warnings;

use Moose;

with 'ShardedKV::Storage';

has 'urls' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1
);

has 'endpoints' => (
    is => 'ro',
    isa => 'ArrayRef[ShardedKV::Storage::Rest]',
    required => 0,
    lazy    => 1,
    builder => '_build_endpoints'
);

has 'max_failures' => (
    is => 'ro',
    isa => 'Int',
    required => 0,
    default => 0
);

has 'use_backoff' => (
    is => 'ro',
    isa => 'Int',
    required => 0,
    default => 1
);

sub _build_endpoints {
    my $self = shift;
    $self->{endpoints} = [];
    push @{$self->{endpoints}}, ShardedKV::Storage::Rest->new(url => $_) for @{$self->urls};
    return $self->{endpoints};
}

sub _maybe_use_endpoint {
    my ($self, $endpoint) = @_;

    if (!$self->{use_backoff}) {
        # don't use backoff -- every endpoint is good to use
        return 1;
    }

    my $state = $self->{endpoint_states}->{$endpoint};

    if (!defined($state) || !$state->{state}) {
        $state->{state} = 'ok';
        $self->{endpoint_states}->{$endpoint} = $state;
        return $endpoint;
    }

    if ($state->{state} eq 'ok' || $state->{state} eq 'warn') {
        return $endpoint;
    }

    if ($state->{state} eq 'retry') {
        # this state transition "shouldn't happen"
        warn "Bad state transition maybe_use(retry)";
        return $endpoint;
    }

    if ($state->{state} eq 'fail') {
        if ($state->{retry_after} < time) {
            $state->{state} = 'retry';
            return $endpoint;
        }
        return undef;
    }

    warn "unknown state: " . $state->{state};

}

sub _mark_endpoint_as_failed {
    my ($self, $endpoint) = @_;

    if (!$self->{use_backoff}) {
        return
    }

    my $state = $self->{endpoint_states}->{$endpoint};

    if ($state->{state} eq 'ok') {
        $state->{state} = 'warn';
        $state->{failure_count} = 1;
    } elsif ($state->{state} eq 'warn') {
        $state->{failure_count}++;
        if ($state->{failure_count} == 5) {
            $state->{state} = 'fail';
            $state->{retry_delay} = 1;
            $state->{retry_after} = time + $state->{retry_delay};
        }
    } elsif ($state->{state} eq 'fail') {
        # this state transition "shouldn't happen"
        warn "Bad state transition failed(fail)";
    } elsif ($state->{state} eq 'retry') {
        $state->{state} = 'fail';
        $state->{retry_delay} *= 2;
        if ($state->{retry_delay} > 60) {
            $state->{retry_delay} = 60;
        }
        $state->{retry_after} = time + $state->{retry_delay};
    } else {
        warn "unknown state: " . $state->{state};
    }
}

sub _mark_endpoint_as_success {
    my ($self, $endpoint) = @_;
    # harmless if we're ignoring backoff logic
    $self->{endpoint_states}->{$endpoint}->{state} = 'ok';
}

sub get {
    my ($self, $key) = @_;

    for my $endpoint (@{$self->endpoints}) {
        next unless $self->_maybe_use_endpoint($endpoint);
        my $data;
        my $caught_exception;
        eval {
            $data = $endpoint->get($key);
            1;
        } or do {
            my $err = $@ || "zombie error";
            $caught_exception = 1;
            warn "caught exception during get($key): $err";
        };

        if ($caught_exception) {
            $self->_mark_endpoint_as_failed($endpoint);
        } else {
            $self->_mark_endpoint_as_success($endpoint);
        }

        if (defined($data)) {
            return $data;
        }
    }

    return undef;
}

sub set {
    my ($self, $key, $value) = @_;

    my $failures = 0;

    for my $endpoint (@{$self->endpoints}) {
        if (!$self->_maybe_use_endpoint($endpoint)) {
            $failures++;
            next;
        }
        my $r;
        my $caught_exception;
        eval {
            $r = $endpoint->set($key, $value);
            1;
        } or do {
            # warn -- error setting key=$key
            $caught_exception = 1;
            $r = 0;
        };

        if ($caught_exception) {
            $self->_mark_endpoint_as_failed($endpoint);
        } else {
            $self->_mark_endpoint_as_success($endpoint);
        }

        if (!$r) {
            $failures++;
        }
    }

    return ($failures > $self->max_failures) ? 0 : 1;
}

sub delete {
    my ($self, $key) = @_;


    my $failures = 0;

    for my $endpoint (@{$self->endpoints}) {
        if (!$self->_maybe_use_endpoint($endpoint)) {
            $failures++;
            next;
        }
        my $r;
        my $caught_exception;
        eval {
            $r = $endpoint->delete($key);
            1;
        } or do {
            # warn -- error deleting key=$key
            $caught_exception = 1;
            $r = 0;
        };

        if ($caught_exception) {
            $self->_mark_endpoint_as_failed($endpoint);
        } else {
            $self->_mark_endpoint_as_success($endpoint);
        }

        if (!$r) {
            $failures++;
        }
    }

    return ($failures > $self->max_failures) ? 0 : 1;
}

sub reset_connection {
    my ($self, $key) = @_;

    my $failures = 0;

    for my $endpoint (@{$self->endpoints}) {
        if (!$self->_maybe_use_endpoint($endpoint)) {
            $failures++;
            next;
        }
        my $r;
        my $caught_exception;
        eval {
            $r = $endpoint->reset_connection($key);
            1;
        } or do {
            $r = 0;
            $caught_exception = 1;
            # warn -- error resetting connection for key=$key
        };

        if ($caught_exception) {
            $self->_mark_endpoint_as_failed($endpoint);
        } else {
            $self->_mark_endpoint_as_success($endpoint);
        }

        if (!$r) {
            $failures++;
        }
    }
    return ($failures > $self->max_failures) ? 0 : 1;
}

1;
