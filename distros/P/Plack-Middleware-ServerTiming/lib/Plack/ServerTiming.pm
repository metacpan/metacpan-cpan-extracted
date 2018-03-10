package Plack::ServerTiming;
use strict;
use warnings;

sub new {
    my ($class, $env) = @_;
    return bless {
        env => $env,
    } => $class;
}

sub record_timing {
    my ($self, $name, $field) = @_;
    $field ||= {};

    push @{ $self->{env}->{'psgix.server-timing'} } => [$name, $field];
}

sub guard {
    my $self = shift;
    return Plack::ServerTiming::Guard->new($self->{env}, @_);
}

package # hide from pause
    Plack::ServerTiming::Guard;
use Time::HiRes;

sub new {
    my ($class, $env, $name, $desc) = @_;
    return bless {
        env   => $env,
        start => [Time::HiRes::gettimeofday],
        name  => $name,
        desc  => $desc,
    }, $class;
}

sub DESTROY {
    my $self = shift;
    my $dur = Time::HiRes::tv_interval($self->{start}) * 1000;
    push @{ $self->{env}->{'psgix.server-timing'} } => [$self->{name}, {dur => $dur, desc => $self->{desc}}];
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Plack::ServerTiming - Frontend for Plack::Middleware::ServerTiming

=head1 SYNOPSIS

    use Plack::ServerTiming;

    builder {
        enable 'ServerTiming';
        sub {
            my $env = shift;
            my $t = Plack::ServerTiming->new($env);
            sleep 1;
            $t->record_timing('miss');
            $t->record_timing(sleep => {dur => 1000, desc => 'Sleep one second...'});
            [200, ['Content-Type','text/html'], ["OK"]];
        };
    };

=head1 DESCRIPTION

This module provides high level API for L<Plack::Middleware::ServerTiming>.

=head1 METHODS

=over 4

=item $timing = Plack::ServerTiming->new($env)

This will create a new instance of L<Plack::SeverTiming>.

=item $timing->record_timing($name, {dur => $duration, desc => $description})

C<record_timing()> adds a metric consisting of name, duration and description.

    $timing->record_timing('total', {dur => 123.4});

=item $timing->guard($name, $description)

C<guard()> creates a guard instance to record a duration. This will add a elapsed
time until exit the scope as metric.

    {
        my $g = $timing->guard('elapsed', 'sleep 1');
        sleep 1;
    }
    # `elapsed;dur=1000.224;desc="sleep 1"`

=back

=head1 SEE ALSO

L<Plack::Middleware::ServerTiming>

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut
