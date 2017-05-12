package Sub::Throttler::Periodic::EV;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;
our @CARP_NOT = qw( Sub::Throttler );

our $VERSION = 'v0.2.10';

use parent qw( Sub::Throttler::Limit );
use Sub::Throttler qw( throttle_flush );
use Time::HiRes qw( time sleep );
use Scalar::Util qw( weaken );
use EV;


sub new {
    use warnings FATAL => qw( misc );
    my ($class, %opt) = @_;
    my $self = bless {
        limit   => delete $opt{limit} // 1,
        period  => delete $opt{period} // 1,
        acquired=> {},  # { $id => { $key => $quantity, … }, … }
        used    => {},  # { $key => $quantity, … }
        }, ref $class || $class;
    croak 'limit must be an unsigned integer' if $self->{limit} !~ /\A\d+\z/ms;
    croak 'period must be a positive number' if $self->{period} <= 0;
    croak 'bad param: '.(keys %opt)[0] if keys %opt;
    weaken(my $this = $self);
    $self->{_t} = EV::periodic 0, $self->{period}, 0, sub { $this && $this->_tick() };
    $self->{_t}->keepalive(0);
    return $self;
}

sub acquire {
    my ($self, $id, $key, $quantity) = @_;
    if (!$self->try_acquire($id, $key, $quantity)) {
        if ($quantity <= $self->{limit} && $self->{used}{$key}) {
            my $time = time;
            my $delay = int($time/$self->{period})*$self->{period} + $self->{period} - $time;
            sleep $delay;
            $self->_tick();
        }
        if (!$self->try_acquire($id, $key, $quantity)) {
            croak "$self: unable to acquire $quantity of resource '$key'";
        }
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
    # time jump backward, no matter how much, handled like we still is in
    # current period, to be safe
    if (int($state->{at}/$self->{period})*$self->{period} + $self->{period} > time) {
        $self->{used} = $state->{used};
    }
    if (keys %{ $self->{used} }) {
        $self->{_t}->keepalive(1);
    }
    return $self;
}

sub period {
    my ($self, $period) = @_;
    if (1 == @_) {
        return $self->{period};
    }
    croak 'period must be a positive number' if $period <= 0;
    $self->{period} = $period;
    $self->{_t}->set(0, $self->{period}, 0);
    return $self;
}

sub release {
    my ($self, $id) = @_;
    croak sprintf '%s not acquired anything', $id if !$self->{acquired}{$id};
    delete $self->{acquired}{$id};
    return $self;
}

sub release_unused {
    my $self = shift->SUPER::release_unused(@_);
    if (!keys %{ $self->{used} }) {
        $self->{_t}->keepalive(0);
    }
    return $self;
}

sub save {
    my ($self) = @_;
    my $state = {
        algo    => __PACKAGE__,
        version => version->declare($VERSION)->numify,
        limit   => $self->{limit},
        period  => $self->{period},
        used    => $self->{used},
        at      => time,
    };
    return $state;
}

sub try_acquire {
    my $self = shift;
    if ($self->SUPER::try_acquire(@_)) {
        $self->{_t}->keepalive(1);
        return 1;
    }
    return;
}

sub _tick {
    my $self = shift;
    for my $id (keys %{ $self->{acquired} }) {
        for my $key (keys %{ $self->{acquired}{$id} }) {
            $self->{acquired}{$id}{$key} = 0;
        }
    }
    # OPTIMIZATION call throttle_flush() only if amount of available
    # resources increased (i.e. if some sources was released)
    if (keys %{ $self->{used} }) {
        $self->{used} = {};
        throttle_flush();
    }
    if (!keys %{ $self->{used} }) {
        $self->{_t}->keepalive(0);
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Sub::Throttler::Periodic::EV - throttle by rate (quantity per time)


=head1 VERSION

This document describes Sub::Throttler::Periodic::EV version v0.2.10


=head1 SYNOPSIS

    use Sub::Throttler::Periodic::EV;
    
    # default limit=1, period=1
    my $throttle = Sub::Throttler::Periodic::EV->new(period => 0.1, limit => 42);
    
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
when current time is divisible by given period value all used resources
will be made available for acquiring again.

It uses EV::periodic, but will avoid keeping your event loop running when
it doesn't needed anymore (if there are no acquired resources).


=head1 EXPORTS

Nothing.


=head1 INTERFACE

L<Sub::Throttler::Periodic::EV> inherits all methods from L<Sub::Throttler::algo>
and implements the following ones.

=head2 new

    my $throttle = Sub::Throttler::Periodic::EV->new;
    my $throttle = Sub::Throttler::Periodic::EV->new(period => 0.1, limit => 42);

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

=head2 load

    my $throttle = Sub::Throttler::Periodic::EV->load($state);

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
