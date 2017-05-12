package Sub::Throttler::Rate::AnyEvent;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;
our @CARP_NOT = qw( Sub::Throttler );

our $VERSION = 'v0.2.10';

use parent qw( Sub::Throttler::algo );
use Sub::Throttler qw( throttle_flush );
use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC time sleep );
use List::Util qw( min );
use Scalar::Util qw( weaken );
use Storable qw( dclone );
use AnyEvent;


sub new {
    use warnings FATAL => qw( misc );
    my ($class, %opt) = @_;
    my $self = bless {
        limit   => delete $opt{limit} // 1,
        period  => delete $opt{period} // 1,
        acquired=> {},      # { $id => { $key => [$time, $quantity], … }, … }
        used    => {},      # { $key => { next => $idx, data => [ $time, … ] }, … }
        _cb     => undef,   # callback for timer
        _t      => undef,   # undef or AE::timer
        }, ref $class || $class;
    croak 'limit must be an unsigned integer' if $self->{limit} !~ /\A\d+\z/ms;
    croak 'period must be a positive number' if $self->{period} <= 0;
    croak 'period is too large' if $self->{period} >= -Sub::Throttler::Rate::rr::EMPTY();
    croak 'bad param: '.(keys %opt)[0] if keys %opt;
    weaken(my $this = $self);
    $self->{_cb} = sub { $this && $this->_tick() };
    return $self;
}

sub acquire {
    my ($self, $id, $key, $quantity) = @_;
    if (!$self->try_acquire($id, $key, $quantity)) {
        if ($quantity <= $self->{limit}) {
            my $now = clock_gettime(CLOCK_MONOTONIC);
            my $delay = $self->{used}{$key}->get($quantity) + $self->{period} - $now;
            $delay = sprintf '%.6f', $delay; # work around floating point precision issues
            # resource may expire between try_acquire() and clock_gettime()
            if ($delay > 0) {
                sleep $delay;
            }
        }
        if (!$self->try_acquire($id, $key, $quantity)) {
            croak "$self: unable to acquire $quantity of resource '$key'";
        }
    }
    return $self;
}

sub limit {
    my ($self, $limit) = @_;
    if (1 == @_) {
        return $self->{limit};
    }
    croak 'limit must be an unsigned integer' if $limit !~ /\A\d+\z/ms;
    # OPTIMIZATION call throttle_flush() only if amount of available
    # resources increased (i.e. limit was increased)
    my $resources_increases = $self->{limit} < $limit;
    $self->{limit} = $limit;
    for my $rr (values %{ $self->{used} }) {
        $rr->resize($self->{limit});
    }
    if ($resources_increases) {
        throttle_flush();
    }
    return $self;
}

sub load {
    my ($class, $state) = @_;
    croak 'bad state: wrong algorithm' if $state->{algo} ne __PACKAGE__;
    my $v = version->parse($state->{version});
    if ($v > $VERSION) {
        carp 'restoring state saved by future version';
    }
    my $self = $class->new(limit=>$state->{limit}, period=>$state->{period});
    $self->{used} = dclone($state->{used});
    my ($time, $now) = (time, clock_gettime(CLOCK_MONOTONIC));
    # time jump backward, no matter how much, handled like we still is in
    # current period, to be safe
    if ($state->{at} > $time) {
        $time = $state->{at};
    }
    my $diff = $time - $now;
    for my $data (map {$_->{data}} values %{ $self->{used} }) {
        for (@{ $data }) {
            if ($_ != Sub::Throttler::Rate::rr::EMPTY()) {
                $_ -= $diff;
                $_ = sprintf '%.6f', $_; # work around floating point precision issues
            }
        }
    }
    for (values %{ $self->{used} }) {
        bless $_, 'Sub::Throttler::Rate::rr';
    }
    $self->{_t} = AE::timer 0, 0, $self->{_cb};
    return $self;
}

sub period {
    my ($self, $period) = @_;
    if (1 == @_) {
        return $self->{period};
    }
    croak 'period must be a positive number' if $period <= 0;
    croak 'period is too large' if $self->{period} >= -Sub::Throttler::Rate::rr::EMPTY();
    # OPTIMIZATION call throttle_flush() only if amount of available
    # resources increased (i.e. period was decreased)
    my $resources_increases = $self->{period} > $period;
    $self->{period} = $period;
    if ($resources_increases) {
        if ($self->{_t}) {
            $self->{_t} = undef;
            $self->_tick();
        }
        else {
            throttle_flush();
        }
    }
    return $self;
}

sub release {
    my ($self, $id) = @_;
    croak sprintf '%s not acquired anything', $id if !$self->{acquired}{$id};
    delete $self->{acquired}{$id};
    return $self;
}

sub release_unused {
    my ($self, $id) = @_;
    croak sprintf '%s not acquired anything', $id if !$self->{acquired}{$id};

    my $now = clock_gettime(CLOCK_MONOTONIC);
    for my $key (grep {$self->{used}{$_}} keys %{ $self->{acquired}{$id} }) {
        my ($time, $quantity) = @{ $self->{acquired}{$id}{$key} };
        $self->{used}{$key}->del($time, $quantity);
        # clean up (avoid memory leak in long run with unique keys)
        if ($self->{used}{$key}->get($self->{limit}) + $self->{period} <= $now) {
            delete $self->{used}{$key};
        }
    }
    delete $self->{acquired}{$id};
    throttle_flush();
    if (!keys %{ $self->{used} }) {
        $self->{_t} = undef;
    }
    return $self;
}

sub save {
    my ($self) = @_;
    my ($time, $now) = (time, clock_gettime(CLOCK_MONOTONIC));
    my $diff = $time - $now;
    my $state = {
        algo    => __PACKAGE__,
        version => version->declare($VERSION)->numify,
        limit   => $self->{limit},
        period  => $self->{period},
        used    => dclone($self->{used}),
        at      => $time,
    };
    for my $data (map {$_->{data}} values %{ $state->{used} }) {
        for (@{ $data }) {
            if ($_ != Sub::Throttler::Rate::rr::EMPTY()) {
                $_ += $diff;
                $_ = sprintf '%.6f', $_; # work around floating point precision issues
            }
        }
    }
    for (values %{ $state->{used} }) {
        $_ = {%{ $_ }}; # unbless
    }
    return $state;
}

sub try_acquire {
    my ($self, $id, $key, $quantity) = @_;
    croak sprintf '%s already acquired %s', $id, $key
        if $self->{acquired}{$id} && exists $self->{acquired}{$id}{$key};
    croak 'quantity must be positive' if $quantity <= 0;

    my $now = clock_gettime(CLOCK_MONOTONIC);

    $self->{used}{$key} ||= Sub::Throttler::Rate::rr->new($self->{limit});
    if (!$self->{used}{$key}->add($self->{period}, $now, $quantity)) {
        return;
    }

    $self->{acquired}{$id}{$key} = [$now, $quantity];
    if (!$self->{_t}) {
        $self->{_t} = AE::timer $self->{period}, 0, $self->{_cb};
    }
    return 1;
}

sub _tick {
    my $self = shift;
    my $now  = clock_gettime(CLOCK_MONOTONIC);
    my $when = 0;
    for my $key (keys %{ $self->{used} }) {
        my $after = $self->{used}{$key}->after($now - $self->{period});
        if (!$after) {
            delete $self->{used}{$key};
        }
        elsif (!$when || $when > $after) {
            $when = $after;
        }
    }
    $self->{_t} = !$when ? undef : AE::timer $when + $self->{period} - $now, 0, $self->{_cb};
    throttle_flush();
    return;
}


package Sub::Throttler::Rate::rr; ## no critic (ProhibitMultiplePackages)
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

use constant EMPTY => -1_000_000_000;


sub new {
    my ($class, $len) = @_;
    my $self = bless {
        next => 0,
        data => [ (EMPTY) x $len ],
        }, ref $class || $class;
    return $self;
}

sub add {
    my ($self, $period, $time, $quantity) = @_;
    $time = sprintf '%.6f', $time; # work around floating point precision issues
    my $len = @{ $self->{data} };
    # try_acquire() guarantee $quantity > 0, so we continue only if $len > 0
    # (thus avoid division by zero on % $len) and there is a chance to add
    # $quantity elements
    if ($quantity > $len) {
        return;
    }
    my $required = ($self->{next} + $quantity - 1) % $len;
    # {data} is sorted, last added element ($self->{next}-1) is guaranteed
    # to be largest of all elements, so all elements between (inclusive)
    # $self->{next} and $required are guaranteed to be either EMPTY
    # or <= $self->{next}-1 element, and $required element is largest of them
    my $since = sprintf '%.6f', $time - $period;     # work around floating point precision issues
    if ($self->{data}[$required] > $since) {
        return;
    }
    for (1 .. $quantity) {
        $self->{data}[ $self->{next} ] = $time;
        ($self->{next} += 1) %= $len;
    }
    return 1;
}

# Return time of acquiring first resource after $time or nothing.
sub after {
    my ($self, $time) = @_;
    $time = sprintf '%.6f', $time; # work around floating point precision issues
    # _tick() guarantee $time > EMPTY
    my $len = @{ $self->{data} };
    for (1 .. $len) {
        $_ = ($self->{next} + $_ - 1) % $len;
        return $self->{data}[ $_ ] if $self->{data}[ $_ ] > $time;
    }
    return;
}

sub del {
    my ($self, $time, $quantity) = @_;
    $time = sprintf '%.6f', $time; # work around floating point precision issues
    # try_acquire() guarantee $quantity > 0
    # even if $time is already outdated, these elements should be removed
    # anyway in case {period} will be increased later
    my $len = @{ $self->{data} };
    if (!$len) {
        return;
    }
    if ($quantity > $len) {
        $quantity = $len;
    }
    # OPTIMIZATION not in {data}
    if ($self->{data}[ $self->{next} ] > $time) {
        return;
    }
    # OPTIMIZATION oldest
    elsif ($self->{data}[ $self->{next} ] == $time) {
        for (map { ($self->{next} + $_ - 1) % $len } 1 .. $quantity) {
            # part of $quantity may be not in {data} (if {limit} was decreased)
            return if $self->{data}[ $_ ] != $time;
            $self->{data}[ $_ ] = EMPTY;
        }
    }
    # OPTIMIZATION newest
    elsif ($self->{data}[ $self->{next} - 1 ] == $time) {
        for (map { $self->{next} - $_ } 1 .. $quantity) {
            croak 'assert: newest: no time' if $self->{data}[ $_ ] != $time;
            $self->{data}[ $_ ] = EMPTY;
        }
        $self->{next} = ($self->{next} - $quantity) % $len;
    }
    # middle (actually it support any case, not just middle)
    else {
        my $i = _binsearch($time, $self->{data}, $self->{next}, $len - 1)
             // _binsearch($time, $self->{data}, 0, $self->{next} - 1);
        croak 'assert: middle: not found' if !defined $i;
        for (map { ($i + $_ - 1) % $len } 1 .. $quantity) {
            croak 'assert: middle: no time' if $self->{data}[ $_ ] != $time;
            $self->{data}[ $_ ] = EMPTY;
        }
        # OPTIMIZATION move minimum amount of elements
        my $count_rew = ($self->{next} - $i) % $len;
        my $count_fwd = ($i + $quantity - $self->{next}) % $len;
        # move oldest elements forward
        if ($count_fwd <= $count_rew) {
            @{ $self->{data} }[ map { ($self->{next}+$_-1) % $len } 1 .. $count_fwd ] =
            @{ $self->{data} }[ map { ($self->{next}+$_-1) % $len } $count_fwd-$quantity+1 .. $count_fwd, 1 .. $count_fwd-$quantity ];
        }
        # move newest elements backward
        else {
            @{ $self->{data} }[ map { ($i+$_-1) % $len } 1 .. $count_rew ] =
            @{ $self->{data} }[ map { ($i+$_-1) % $len } 1+$quantity .. $count_rew, 1 .. $quantity];
            $self->{next} = ($self->{next} - $quantity) % $len;
        }
    }
    return;
}

sub get {
    my ($self, $id) = @_;
    # $id is number of required element, counting from oldest one ($id = 1)
    my $len = @{ $self->{data} };
    # acquire() guarantee 0 < $id <= $len
    my $i = ($self->{next} + $id - 1) % $len;
    return $self->{data}[$i];
}

sub resize {
    my ($self, $newlen) = @_;
    # limit() guarantee $newlen >= 0
    my $len = @{ $self->{data} };
    my $d = $self->{data};
    $self->{data} = [ @{$d}[ $self->{next} .. $#{$d} ], @{$d}[ 0 .. $self->{next} - 1 ] ];
    if ($newlen < $len) {
        $self->{next} = 0;
        splice @{ $self->{data} }, 0, $len - $newlen;
    } else {
        $self->{next} = $len % $newlen;
        push @{ $self->{data} }, (EMPTY) x ($newlen - $len);
    }
    return $self;
}

# From List::BinarySearch::PP version 0.23.
# Modified to support slices and work with array of numbers, without callback.
sub _binsearch {
    my ( $target, $aref, $min, $max ) = @_;
    $min //= 0;
    $max //= $#{$aref};
    croak 'bad slice' if $min < 0 || $#{$aref} < $max || $min > $max;
    while ( $max > $min ) {
        my $mid = int( ( $min + $max ) / 2 );
        if ( $target > $aref->[$mid] ) {
            $min = $mid + 1;
        } else {
            $max = $mid;
        }
    }
    return $min if $target == $aref->[$min];
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Sub::Throttler::Rate::AnyEvent - throttle by rate (quantity per time)


=head1 VERSION

This document describes Sub::Throttler::Rate::AnyEvent version v0.2.10


=head1 SYNOPSIS

    use Sub::Throttler::Rate::AnyEvent;
    
    # default limit=1, period=1
    my $throttle = Sub::Throttler::Rate::AnyEvent->new(period => 0.1, limit => 42);
    
    my $limit = $throttle->limit;
    $throttle->limit(42);
    my $period = $throttle->period;
    $throttle->period(0.1);
    
    # --- Activate throttle for selected subrouties
    $throttle->apply_to_functions('Some::func', 'Other::func2', …);
    $throttle->apply_to_methods('Class', 'method', 'method2', …);
    $throttle->apply_to_methods($object, 'method', 'method2', …);
    $throttle->apply_to(sub {
      my ($this, $name, @params) = @_;
      ...
      return;   # OR
      return { key1=>$quantity1, ... };
    });
    
    # --- Manual resource management
    if ($throttle->try_acquire($id, $key, $quantity)) {
        ...
        $throttle->release($id);
        $throttle->release_unused($id);
    }


=head1 DESCRIPTION

This is a plugin for L<Sub::Throttler> providing simple algorithm for
throttling by rate (quantity per time) of used resources.

This algorithm works like L<Sub::Throttler::Limit> with one difference:
resources acquired earlier than given period value will be made available
for acquiring again.

It uses AE::timer, but will avoid keeping your event loop running when it
doesn't needed anymore (if there are no acquired resources).

For throttling sync subs this algorithm can be used even without event
loop, but if you'll use huge amount of unique resource names in
long-running application then some memory will leak.


=head1 EXPORTS

Nothing.


=head1 INTERFACE

L<Sub::Throttler::Rate::AnyEvent> inherits all methods from L<Sub::Throttler::algo>
and implements the following ones.

=head2 new

    my $throttle = Sub::Throttler::Rate::AnyEvent->new;
    my $throttle = Sub::Throttler::Rate::AnyEvent->new(period => 0.1, limit => 42);

Create and return new instance of this algorithm.

Default C<period> is C<1.0>, C<limit> is C<1>.

See L<Sub::Throttler::algo/"new"> for more details.

=head2 period

    my $period = $throttle->period;
    $throttle  = $throttle->period($period);

Get or modify current C<period>.

=head2 limit

    my $limit = $throttle->limit;
    $throttle = $throttle->limit(42);

Get or modify current C<limit>.

NOTE: After decreasing C<limit> in some case maximum of limits used while
current C<period> may be used instead of current C<limit> for next C<period>.

=head2 load

    my $throttle = Sub::Throttler::Rate::AnyEvent->load($state);

Create and return new instance of this algorithm.

See L<Sub::Throttler::algo/"load"> for more details.

=head2 save

    my $state = $throttle->save();

Return current state of algorithm needed to restore it using L</"load">
after application restart.

See L<Sub::Throttler::algo/"save"> for more details.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Sub-Throttler/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Sub-Throttler>

    git clone https://github.com/powerman/perl-Sub-Throttler.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Sub-Throttler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Sub-Throttler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Throttler>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Sub-Throttler>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Sub-Throttler>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
