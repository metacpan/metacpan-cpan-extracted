package Sub::Throttler::Limit;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;
our @CARP_NOT = qw( Sub::Throttler Sub::Throttler::Periodic::EV );

our $VERSION = 'v0.2.10';

use parent qw( Sub::Throttler::algo );
use Sub::Throttler qw( throttle_flush );


sub new {
    use warnings FATAL => qw( misc );
    my ($class, %opt) = @_;
    my $self = bless {
        limit   => delete $opt{limit} // 1,
        acquired=> {},  # { $id => { $key => $quantity, … }, … }
        used    => {},  # { $key => $quantity, … }
        }, ref $class || $class;
    croak 'limit must be an unsigned integer' if $self->{limit} !~ /\A\d+\z/ms;
    croak 'bad param: '.(keys %opt)[0] if keys %opt;
    return $self;
}

sub acquire {
    my ($self, $id, $key, $quantity) = @_;
    if (!$self->try_acquire($id, $key, $quantity)) {
        croak "$self: unable to acquire $quantity of resource '$key'";
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
    my $self = $class->new(limit=>$state->{limit});
    return $self;
}

sub release {
    return _release(@_);
}

sub release_unused {
    return _release(@_);
}

sub save {
    my ($self) = @_;
    my $state = {
        algo    => __PACKAGE__,
        version => version->declare($VERSION)->numify,
        limit   => $self->{limit},
        used    => $self->{used},
        at      => time,
    };
    return $state;
}

sub try_acquire {
    my ($self, $id, $key, $quantity) = @_;
    croak sprintf '%s already acquired %s', $id, $key
        if $self->{acquired}{$id} && exists $self->{acquired}{$id}{$key};
    croak 'quantity must be positive' if $quantity <= 0;

    my $used = $self->{used}{$key} || 0;
    if ($used + $quantity > $self->{limit}) {
        return;
    }
    $self->{used}{$key} = $used + $quantity;

    $self->{acquired}{$id}{$key} = $quantity;
    return 1;
}

sub _release {
    my ($self, $id) = @_;
    croak sprintf '%s not acquired anything', $id if !$self->{acquired}{$id};

    for my $key (keys %{ $self->{acquired}{$id} }) {
        my $quantity = $self->{acquired}{$id}{$key};
        $self->{used}{$key} -= $quantity;
        # clean up (avoid memory leak in long run with unique keys)
        if (!$self->{used}{$key}) {
            delete $self->{used}{$key};
        }
    }
    delete $self->{acquired}{$id};
    throttle_flush();
    return $self;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Sub::Throttler::Limit - throttle by quantity


=head1 VERSION

This document describes Sub::Throttler::Limit version v0.2.10


=head1 SYNOPSIS

    use Sub::Throttler::Limit;
    
    my $throttle = Sub::Throttler::Limit->new(limit => 5);
    
    $throttle->apply_to_methods(Mojo::UserAgent => qw( get post ));


=head1 DESCRIPTION

This is a plugin for L<Sub::Throttler> providing simple algorithm for
throttling by quantity of used resources.

In a nutshell it's just a hash, with resource names as keys and currently
used resource quantities as values; plus one limit on maximum quantity
applied to any key. Of course, each instance will have own hash/limit.

When you configure it you define which functions/methods it should
throttle, and which resource name(s) and quantity(ies) of that resource(s)
each function/method should acquire to run.

In basic use case you'll use one instance and configure it using
L<Sub::Throttler::algo/"apply_to_functions"> and/or
L<Sub::Throttler::algo/"apply_to_methods"> helpers - which
result in any throttled function/method will need C<1> resource named
C<"default"> to run. This way you'll effectively use just one counter,
which will increase when any throttled function/method run and decrease
when it finish, so you will have up to C<limit> simultaneously running
functions/methods (C<limit> is usually set when you call L</"new">).

    my $throttle_tasks = Sub::Throttler::Limit->new(limit => 5);
    $throttle_tasks->apply_to_functions('run_background_task');
    # This code will start 5 background tasks but last two will be
    # put into queue instead of being started. When any of started
    # background tasks will finish first one of queued tasks will be
    # started, etc. Usually you'll need event loop or something else
    # to make this really works, but this has nothing with throttling.
    for (1..7) {
        run_background_task();
    }
    # this function must support throttling
    sub run_background_task { ... }

In advanced use case you may use many counters in one instance (by using
L<Sub::Throttler::algo/"apply_to"> to define different resource
names/quantities for different throttled functions/methods) and have many
instances (with different C<limit>) throttling same or different
functions/methods.

    my $throttle_tasks = Sub::Throttler::Limit->new(limit => 5);
    my $throttle_cpu   = Sub::Throttler::Limit->new(limit => 100);
    # allow to simultaneously run up to 5 side_task() plus up to:
    # - 5 small_task() or
    # - 2 normal_task() plus 1 small_task() or
    # - 1 large_task() plus 1 normal_task() or
    # - 1 large_task() plus 2 small_task()
    $throttle_tasks->apply_to(sub {
        my ($this, $name, @param) = @_;
        if ($name eq 'small_task') {
            return { task => 1 };
        } elsif ($name eq 'normal_task') {
            return { task => 2 };
        } elsif ($name eq 'large_task') {
            return { task => 3 };
        } elsif ($name eq 'side_task') {
            return { side => 1 };
        }
        return;
    });
    # and apply extra limitation on amount of simultaneously running
    # side_task() depending on it first parameter (number between 1 and
    # 100 showing how much CPU this side_task() will use)
    $throttle_cpu->apply_to(sub {
        my ($this, $name, @param) = @_;
        if ($name eq 'side_task') {
            return { default => $param[0] };
        }
        return;
    });
    # here is how it will works:
    large_task();   # started ($throttle_tasks 'task' == 3)
    side_task(60);  # started ($throttle_tasks 'side' == 1,
                    #          $throttle_cpu 'default' == 60)
    small_task();   # started ($throttle_tasks 'task' == 4)
    normal_task();  # delayed ($throttle_tasks 'task' + 2 > limit)
    side_task(30);  # started ($throttle_tasks 'side' == 2,
                    #          $throttle_cpu 'default' == 90)
    side_task(30);  # delayed ($throttle_cpu 'default' + 30 > limit)


=head1 EXPORTS

Nothing.


=head1 INTERFACE

L<Sub::Throttler::Limit> inherits all methods from L<Sub::Throttler::algo>
and implements the following ones.

=head2 new

    my $throttle = Sub::Throttler::Limit->new;
    my $throttle = Sub::Throttler::Limit->new(limit => 42);

Create and return new instance of this algorithm.

Default C<limit> is C<1>.

See L<Sub::Throttler::algo/"new"> for more details.

=head2 limit

    my $limit = $throttle->limit;
    $throttle = $throttle->limit(42);

Get or modify current C<limit>.

=head2 load

    my $throttle = Sub::Throttler::Limit->load($state);

Create and return new instance of this algorithm.

Only L<limit> is restored. Information about acquired resources won't be
restored because there is no way to release these resources later.

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
