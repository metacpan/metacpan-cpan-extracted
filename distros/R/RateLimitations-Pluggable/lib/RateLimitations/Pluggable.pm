package RateLimitations::Pluggable;

use strict;
use warnings;

use Carp;
use Moo;

our $VERSION = '0.02';

=head1 NAME

RateLimitations::Pluggable - pluggabe manager of per-service rate limitations

=head1 STATUS

=begin HTML

<p>
    <a href="https://travis-ci.org/binary-com/perl-RateLimitations-Pluggable"><img src="https://travis-ci.org/binary-com/perl-RateLimitations-Pluggable.svg" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    my $storage = {};

    my $rl = RateLimitations::Pluggable->new({
        limits => {
            sample_service => {
                60   => 2,  # per minute limits
                3600 => 5,  # per hour limits
            }
        },
        # define an subroutine where hits are stored: redis, db, file, in-memory, cookies
        getter => sub {
            my ($service, $consumer) = @_;
            return $storage->{$service}->{$consumer};
        },
        # optional, notify back when hits are updated
        setter => sub {
            my ($service, $consumer, $hits) = @_;
            $storage->{$service}->{$consumer} = $hits;
        },
    });

    $rl->within_rate_limits('sample_service', 'some_client_id');  # true!
    $rl->within_rate_limits('sample_service', 'some_client_id');  # true!
    $rl->within_rate_limits('sample_service', 'some_client_id'),  # false!


=head1 DESCRIPTION

The module access to build-in C<time> function every time you invoke
C<within_rate_limits> method, and checks whether limits are hits or not.

Each time the method C<within_rate_limits> is invoked it appends
to the array of hit current time. It check that array will not
grow endlessly, and holds in per $service (or per $service/$consumer)
upto max_time integers.

The array can be stored anywhere (disk, redis, DB, in-memory), hence the module
name is.

=cut

=head1 ATTRIBUTES

=head2 limits

Defines per-service limits. Below

    {
        service_1 => {
            60   => 20,    # up to 20 service_1 invocations per 1 minute
            3600 => 50,    # OR up to 50 service_1 invocations per 1 hour
        },

        service_2 => {
            60   => 25,
            3600 => 60,
        }

    }

Mandatory.

=head2 getter->($service, $consumer)

Mandatory coderef which returns an array of hits for the service and some
C<consumer>.


=head2 setter->($service, $consumer, $hits)

Optional callback for storing per service/consumer array of hits.

=cut

has limits => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        croak "limits must be a hashref"
            unless (ref($_[0]) // '') eq 'HASH';
    },
);
has getter => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        croak "limits must be a coderef"
            unless (ref($_[0]) // '') eq 'CODE';
    },
);

has setter => (
    is       => 'ro',
    required => 0,
    isa      => sub {
        croak "limits must be a coderef"
            if defined($_[0]) && (ref($_[0] ne 'CODE'));
    },
);

# key: service name
# value: sorted by $seconds array of pairs [$seconds, $rate]
has _limits_for => (is => 'rw');

=for Pod::Coverage BUILD getter setter

=cut

sub BUILD {
    my $self = shift;
    my %limits_for;
    for my $service (keys %{$self->limits}) {
        my @service_limits =
            sort { $a->[0] <=> $b->[0] }
            map {
            my $seconds = $_;
            my $limit   = $self->limits->{$service}->{$seconds};
            [$seconds, $limit];
            } keys %{$self->limits->{$service}};

        # do various validations
        for my $idx (0 .. @service_limits - 1) {
            my $pair = $service_limits[$idx];
            my ($seconds, $limit) = @$pair;

            # validate: seconds should be natural number
            croak("'$seconds' seconds is not integer for service $service")
                if $seconds != int($seconds);
            croak("'$seconds' seconds is not positive for service $service")
                if $seconds <= 0;

            # validate: limit should be natural number
            croak("limit '$limit' is not integer for service $service")
                if $limit != int($limit);
            croak("limit '$limit' is not positive for service $service")
                if $limit <= 0;

            # validate: limit for greater time interval should be greater
            if ($idx > 0) {
                my $prev_pair     = $service_limits[$idx - 1];
                my $lesser_limit  = $prev_pair->[1];
                my $current_limit = $limit;
                if ($current_limit <= $lesser_limit) {
                    croak "limit ($current_limit) for "
                        . $seconds
                        . " seconds"
                        . " should be greater then limit ($lesser_limit) for "
                        . $prev_pair->[0]
                        . "seconds";
                }
            }
        }
        $limits_for{$service} = \@service_limits;
    }
    return $self->_limits_for(\%limits_for);
}

=head1 METHODS

=head2 within_rate_limits

 within_rate_limits($service, $consumer)

Appends service/consumer hits array with additional hit.

Returns true if the service limits aren't exhausted.

The C<$service> string must be defined in the C<limits> attribute;
the C<$consumer> string is arbitrary object defined by application
logic. Cannot be C<undef>

=cut

sub within_rate_limits {
    my ($self, $service, $consumer) = @_;
    croak "service should be defined"  unless defined $service;
    croak "consumer should be defined" unless defined $consumer;

    my $limits = $self->_limits_for->{$service};
    croak "unknown service: '$service'" unless defined $limits;

    my $hits          = $self->getter->($service, $consumer) // [];
    my $within_limits = 1;
    my $now           = time;
    # We push first so that we hit limits more often in heavy (DoS) conditions
    push @$hits, $now;
    # Remove extra oldest hits, as they do not participate it checks anyway
    shift @$hits while (@$hits > $limits->[-1]->[0]);

    # optionally notify updated service hits
    my $setter = $self->setter;
    $setter->($service, $consumer, $hits) if $setter;

    for my $rate (@$limits) {
        # take the service time hit which occur exactly $max_rate times ago
        # might be undefined.
        # +1 is added because we already inserted $now hit above, which
        # should be out of the consideration
        my $past_hit_time = $hits->[($rate->[1] + 1) * -1] // 0;
        my $allowed_past_hit_time = $now - $rate->[0];
        if ($past_hit_time > $allowed_past_hit_time) {
            $within_limits = 0;
            last;
        }
    }

    return $within_limits;
}

=head1 SOURCE CODE

L<GitHub|https://github.com/binary-com/perl-RateLimitations-Pluggable>


=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/binary-com/perl-RateLimitations-Pluggable/issues>.


=cut

1;
