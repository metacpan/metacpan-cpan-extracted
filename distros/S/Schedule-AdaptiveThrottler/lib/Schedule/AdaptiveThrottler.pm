package Schedule::AdaptiveThrottler;

use warnings;
use strict;

our $VERSION = '0.06';
our $DEBUG   = 0;
our $QUIET   = 0;

use Scalar::Util qw(reftype blessed);
use Digest::MD5 qw(md5_hex);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(&authorize &set_client);
our @EXPORT    = qw(
    SCHED_ADAPTHROTTLE_AUTHORIZED
    SCHED_ADAPTHROTTLE_BLOCKED
);
our %EXPORT_TAGS = ( ALL => [ @EXPORT_OK, @EXPORT ] );

use constant SCHED_ADAPTHROTTLE_BLOCKED    => 0;
use constant SCHED_ADAPTHROTTLE_AUTHORIZED => 1;

my $memcached_client;    # used for the non-OO form

sub set_client {
    my $client = pop;     # keep ordered
    my $self   = shift;
    die "Invalid storage client object\n"
        if ( !blessed($client)
        || !$client->can('set')
        || !$client->can('get') );
    return $memcached_client = $client if !blessed $self;    # non-OO form
    return $self->{memcached_client} = $client;              # Guess what? OO-form
}

# OO-style
sub new {
    my $class = shift;
    my $params;
    if ( @_ == 1 ) {
        if ( !blessed $_[0] ) {
            $params = shift;
        }
        else {
            $params->{memcached_client} = shift;
        }
    }
    else {
        $params = {@_};
    }
    my $self = bless $params, $class;
    $self->set_client( $params->{memcached_client} )
        if $params->{memcached_client};
    return $self;
}

sub authorize {

    my %params;
    my $self;

    # Call it as a method or a sub, with a hash or a hashref,
    # as a class or an instance
    if ( @_ < 3 ) {
        %params = %{ pop() };
        $self   = shift;
    }
    else {
        $self = shift if ( @_ % 2 );
        %params = @_;
    }
    my $cur_memcached_client
        = blessed $self ? $self->{memcached_client} : $memcached_client;    # can it get uglier?

    my $frozen_time = time;
    my %conditions;

    # Check the conditions

    my $condition_type;
    for my $condition_type_tmp (qw(all either)) {

        if ( exists $params{$condition_type_tmp}
            && reftype $params{$condition_type_tmp} eq 'HASH' )
        {
            %conditions = %{ $params{$condition_type_tmp} };
            die "Conditions improperly defined (must be a hashref)"
                if !%conditions;

            # Check the parameters

            for my $condition_params ( values %conditions ) {
                for my $condition_param_key (qw{max ttl message value}) {

                    # message & value are strings (or just anything for 'value'), the rest are integers
                    die
                        "Condition parameter $condition_param_key is '$condition_params->{$condition_param_key}'"
                        if !$condition_params->{$condition_param_key};
                    die "Condition parameter $condition_param_key must be positive integer"
                        if ( ( $condition_param_key eq 'max' || $condition_param_key eq 'ttl' )
                        && $condition_params->{$condition_param_key} !~ /^[1-9][0-9]*$/ );
                }
            }
            $condition_type = $condition_type_tmp;
            last;    # process either 'all' or 'either', not both
        }
    }
    die "No conditions defined"
        if !$condition_type;

    # if lockout is defined, use the 'lockout/ban' scheme.  if not, we'll use a
    # bucket algorithm
    my $lockout = $params{lockout};
    die "'Lockout' parameter must be positive integer"
        if ( defined $lockout && $lockout !~ /^[1-9][0-9]*$/ );

    my $identifier = $params{identifier};
    die "'Identifier' should be a non-empty string"
        if ( !defined $identifier || length($identifier) < 1 );

    # Loop on the conditions. For 'either', we need to find one that is not yet
    # satisfied, for 'all' we need to find lockouts for all of them

    # Make the memcached keys a identifier + key name + value
    # TODO: Retrieve the records in 1 operation with get_multi
    # @conditions_names = sort keys %conditions;
    # @keys = map { $_ . '#' . $conditions{$_}->{value} } @conditions_names ) {

    my ( $conditions_ok, $conditions_unknown ) = ( 0, 0 );
    my $messages_notok = [];

    while ( my ( $condition_name, $condition ) = each %conditions ) {
        my $memcached_key = $identifier . '#' . $condition_name . '#' . $condition->{value};
        $memcached_key = md5_hex($memcached_key) if length $memcached_key > 249;

        my $record = $cur_memcached_client->get($memcached_key);

        if ( defined $record ) {

            # Do we have a 'block' value in the record, in which case we return
            # a message indicating so. The 'block' record will be automatically
            # removed from memcached at the object's expiry time, so don't
            # touch it.
            if ( $record eq 'block' ) {
                push @$messages_notok, $condition->{message};
                print STDERR "Access already blocked by " . __PACKAGE__ . "\n"
                    if $DEBUG;
            }

            # the object in memcached is a list of timestamps, and nothing else.
            elsif ( reftype $record eq 'ARRAY' ) {
                print STDERR "Current timestamps in \$record:  " . join( '|', @$record ) . "\n"

                    if $DEBUG;
                print STDERR "Current frozen time: $frozen_time" . "\n"
                    if $DEBUG;

                # cleanup the records (remove expired timestamps). This is
                # where it all happens, giving us this "magic sliding time
                # window".
                @$record = grep { $_ > $frozen_time } @$record;
                print STDERR "Currently unexpired timestamps in \$record:  "
                    . join( '|', @$record ) . "\n"

                    if $DEBUG;

                # Since we are about to add a record, if we already have the
                # max number of records, set to blocked. If no lockout time
                # specified, use the bucket algorithm: deny access, but do not
                # update the record. The expired timestamps will be evicted in
                # due time (next access, possibly), giving us more tokens.
                print STDERR "Maximum is "
                    . $condition->{max}
                    . " and current number of timestamps is "
                    . @$record . "\n"

                    if $DEBUG;
                if ( @$record >= $condition->{max} ) {
                    print STDERR "Maximum reached" . "\n"
                        if $DEBUG;
                    if ($lockout) {
                        print STDERR "Setting a timed lock" . "\n"
                            if $DEBUG;
                        $cur_memcached_client->set( $memcached_key, 'block', $lockout );
                    }
                    push @$messages_notok, $condition->{message};
                }

                # Add a timestamp to the list. This is NOT the current
                # timestamp, but a timestamp in the future (a TTL record),
                # which allowws for easy filtering by the grep above. And set
                # the memcached record expiration time at the most recent TTL
                # of the list (for automatic cleanup: the object will be
                # discarded from memcached automatically if it is not updated
                # before the longest TTL)
                else {
                    print STDERR "Adding a timestamp to the list" . "\n"
                        if $DEBUG;
                    push @$record, $frozen_time + $condition->{ttl};
                    $cur_memcached_client->set( $memcached_key, $record, $condition->{ttl} );
                    $conditions_ok++;
                }
            }
            else {    # This should not happen, but catch it if it does.
                $conditions_unknown++;
            }
        }

        # $record is undef, either not accessible, or not yet created
        else {
            print STDERR "No record found, creating a new one" . "\n"
                if $DEBUG;
            my $ret
                = $cur_memcached_client->set( $memcached_key,
                [ $condition->{ttl} + $frozen_time ],
                $condition->{ttl} );
            $conditions_ok++;
        }
    }

    if ( $conditions_unknown && !$QUIET ) {
        warn "Unknown conditions count is over 0, this should not happen";
        print STDERR "Current conditions hash: " . Dumper( \%conditions ) . "\n";
    }

    # If logic was 'either', 1 'notok' or more should block
    # If logic was 'all', we should have 0 'ok' to block
    # TODO: re-work the variable names because the explanation above is a bit
    # tricky although the logic is correct :(
    if ( $condition_type eq 'either' ) {
        return ( @$messages_notok > 0 )
            ? ( SCHED_ADAPTHROTTLE_BLOCKED, $messages_notok )
            : ( SCHED_ADAPTHROTTLE_AUTHORIZED, undef );
    }
    else {    # condition is 'all'
        return ( $conditions_ok == 0 )
            ? ( SCHED_ADAPTHROTTLE_BLOCKED, $messages_notok )
            : ( SCHED_ADAPTHROTTLE_AUTHORIZED, undef );
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Schedule::AdaptiveThrottler - Throttle just about anything with ease

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

Limit resource use, according to arbitrary parameters, using a bucket algorithm
with counters stored in memcached.

=over 4

=item Protect an HTML authentication form

Ban for 5 minutes if more than 5 login attempts for a given username in less
than a minute, OR if more than 50 login attempts from a single IP addressin
less than 5 minutes.

    use Schedule::AdaptiveThrottler;

    Schedule::AdaptiveThrottler->set_client(Cache::Memcached::Fast->new(...));

    my ( $status, $msg ) = Schedule::AdaptiveThrottler->authorize(
        either => {
            ip    => {
                max     => 50,
                ttl     => 300,
                message => 'ip_blocked',
                value   => $client_ip_address,
            },
            login => {
                max     => 5,
                ttl     => 60,
                message => 'login_blocked',
                value   => $username,
            },
        },
        lockout    => 600,
        identifier => 'user_logon',
    );

    return HTTP_FORBIDDEN if $status == SCHED_ADAPTHROTTLE_BLOCKED;

    ...

=item Robot throttling

Allow at most 10 connection per second for a robot, but do not ban.

    my ( $status, $msg ) = Schedule::AdaptiveThrottler->authorize(
        all => {
            'ip_ua' => {
                max     => 10,
                ttl     => 1,
                message => 'ip_ua_blocked',
                value   => $client_ip_address .'_'. $user_agent_or_something,
            },
        },
        identifier => 'robot_connect',
    );

    return HTTP_BANDWIDTH_LIMIT_EXCEEDED, '...' if $status == SCHED_ADAPTHROTTLE_BLOCKED;

=item OO-style

    use Schedule::AdaptiveThrottler;

    my $SAT = Schedule::AdaptiveThrottler->new(
        memcached_client => Cache::Memcached::Fast->new(...));

    my ( $status, $msg ) = $SAT->authorize(...)

=back

=head1 EXPLANATION

This module was originally designed to throttle access to web forms, and help
prevent brute force attacks and DoS conditions. What it does is very simple:
store lists of timestamps, one for each set of parameter defined in the
authorize() call, check the number of timestamps in the previously generated
list isn't over the threshold set in the call, cleanup the list of expired
timestamps from the list, and put the list back in memcached.

It is really a simple bucket algorithm, helped by some of memcached's features
(specifically the automatic cleanup of expired records, particularly useful
when a ban has been specified).

The interesting thing about it is it can count and throttle anything: if you
need to restrict access to a DB layer to a certain number of calls per minute
per process, for instance, you can do it the exact same way as in the examples
above. Simply use the PID as the 'value' key, and you're set. The possible
applications are endless.

It was written to be fast, efficient, and simpler than other throttling modules
found on CPAN. All what we found was either too complicated, or not fast
enough. Using memcached, a list and a grep on timestamps, where the criteria
(an IP address for instance) are part of the object key, proved satisfactory in
all respects. In particular, we didn't want something using locks, which
introduces a DoS risk all by itself.

=head1 CLASS METHODS

These methods can be used as functions as well, since they are in the
@EXPORT_OK list.

=over 4

=item set_client

Set the memcached instance to be used. Takes a Cache::Memcached or
Cache::Memcached::Fast object as first and only parameter. The value is stored
in a class variable, so only one call is needed. It could be any other object
acting as a Cache::Memcached instance (only get() and set() are needed,
really).

=item authorize

Takes a hash or hashref as argument, along these lines:

    authorize(
        <'either'|'all'> => {
            <arbitrary_parameter_name> => {
                max     => <maximum tries>,
                ttl     => <seconds before a record is wiped>,
                message => '<arbitrary message sent back to caller on "blocked">',
                value   => <arbitrarily defined value for grouping>,
            },
            ...
        },
        [ lockout => <ban duration in seconds, if any>, ]
        identifier => '<disambiguation string for memcached key>',
    )

The returned value is a list. The first element is a constant (see
L<EXPORTED CONSTANTS>) and the second element is an arrayref of all the
messages (individually defined in the parameter list for each condition, see
above) for which a block/ban was decided by the counter mechanism.

If the conditions hashref is defined in 'all', all conditions have to be met
for a block or ban to be issued. If it is defined in 'either', any condition
meeting the limits will trigger it.

Since this is meant to be as non-blocking as possible, failure to communicate
with the memcached backend will not issue a ban.  The return value of the
get/set memcached calls could probably benefit from a more clever approach.

=item new

Use the OO-style instead. A Schedule::AdaptiveThrottler object can be
initialized with a memcached object as a single argument, a hashref containing
parameters (one of which optionally being memcached_client) or a hash with the
same arguments.

=back

=head1 EXPORTED CONSTANTS

=over 4

=item SCHED_ADAPTHROTTLE_AUTHORIZED

=item SCHED_ADAPTHROTTLE_BLOCKED

=back

These 2 constants are used to compare with the value of the first member of
the array returned by L<authorize()>.  They are currently 1 and 0, but that may
change and there could be additions in the future. So do not use true/false on
the result of L<authorize()>, since it won't tell you what you think it will.

=head1 NOTES

The discussion came to a point where we thought it would be more efficient to
store timestamp:count:timestamp:count:...  However benchmarks showed no
difference in performance, only in storage size (and even that only under
certain conditions, like many hits in the same second).

=head1 CAVEATS

Since there is no locking mechanism, which would introduce a serious DoS risk,
it can happen that 2 calls to get() and set() are interleaved, leading to one
of the hits to be ignored. It should not be very common though, given the
typical time between a get() and a set() plus the memcached round-trip, but it
cannot be guaranteed the hits count will always be exact. This should however
not be a problem for the typical use cases. However, if you need a precise
count, use a different module (and be prepared to try and solve the tricky
locking/DoS conditions mentioned above...)

=head1 BUGS

Please report any bugs or feature requests to C<bug-schedule-adaptivethrottler
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Schedule::AdaptiveThrottler>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Schedule::AdaptiveThrottler

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Schedule::AdaptiveThrottler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Schedule::AdaptiveThrottler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Schedule::AdaptiveThrottler>

=item * Search CPAN

L<http://search.cpan.org/dist/Schedule::AdaptiveThrottler/>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Philippe "BooK" Bruhat

=item Dennis Kaarsemaker

=item Kristian Köhntopp

=item Elizabeth Mattijsen

=item Ruud Van Tol

=back

This module really is the product of collective thinking.

=head1 AUTHOR

David Morel, C<< <david.morel at amakuru.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 David Morel & Booking.com.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

