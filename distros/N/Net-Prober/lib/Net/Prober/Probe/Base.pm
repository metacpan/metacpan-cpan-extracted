package Net::Prober::Probe::Base;
$Net::Prober::Probe::Base::VERSION = '0.17';
use strict;
use warnings;

use Carp ();
use Time::HiRes ();
use Sys::Syslog ();

our $USE_SYSLOG = 0;

sub new {
    my ($class, $opt) = @_;

    $opt ||= {};
    $class = ref $class || $class;

    my $self = {
        %{ $opt },
    };

    bless $self, $class;
}

sub name {
    my ($self) = @_;
    my $class = ref $self || $self;
    if ($class =~ m{^ .* :: (?<probename>.*?) $}x) {
        return $+{probename};
    }

    Carp::croak("Couldn't determine the probe name from class $class");
}

sub probe_failed {
    my ($self, %info) = @_;

    my $name = $self->name();

    if (! exists $info{time}) {
        my $elapsed = exists $self->{_time}
            ? $self->time_elapsed()
            : 0.0;
        $info{time} = $elapsed;
    }

    if ($USE_SYSLOG) {
        my $msg = sprintf "Probe %s failed, reason %s, elapsed: %3.2f s",
            $name,
            $info{reason} || 'unknown',
            $info{time};

        Sys::Syslog::syslog('warning', $msg);
    }

    return { ok => 0, %info };
}

sub probe_ok {
    my ($self, %info) = @_;

    my $name = $self->name();

    if (! exists $info{time}) {
        my $elapsed = exists $self->{_time}
            ? $self->time_elapsed()
            : 0.0;
        $info{time} = $elapsed;
    }

    if ($USE_SYSLOG) {
        my $msg = sprintf "Probe %s ok, elapsed: %3.2f s",
            $name, $info{time};
        Sys::Syslog::syslog('info', $msg);
    }

    return { ok => 1, %info };
}

sub time_now {
    my ($self) = @_;

    return $self->{_time} = [ Time::HiRes::gettimeofday() ];
}

sub time_elapsed {
    my ($self) = @_;

    if (! exists $self->{_time} || ! defined $self->{_time}) {
        Carp::croak('time_elapsed() called without a starting time_now()');
    }

    my $last_mark = $self->{_time};
    my $elapsed = Time::HiRes::tv_interval($last_mark);

    return $elapsed;
}

sub process_defaults {
    my ($self, $args) = @_;

    $args ||= {};
    my %args_with_defaults = %{ $args };

    # Process and inject defaults if an arg is not supplied
    my $defaults = $self->defaults;

    if ($defaults && ref $defaults eq 'HASH') {
        for (keys %{ $defaults }) {
            $args_with_defaults{$_} = $defaults->{$_}
                if ! exists $args_with_defaults{$_};
        }
    }

    return \%args_with_defaults;
}

sub parse_args {
    my ($self, $args, @wanted) = @_;

    my $args_with_def = $self->process_defaults($args);

    if (exists $args_with_def->{port} && defined $args_with_def->{port}) {
        $args_with_def->{port} = Net::Prober::port_name_to_num(
            $args_with_def->{port}
        );
    }

    if (! @wanted) {
        return $args_with_def;
    }

    my @arg_values;
    push @arg_values, $args_with_def->{$_} for @wanted;

    return @arg_values;
}

sub defaults {
    Carp::croak("defaults() is an abstract method. You must implement it in your class.");
}

sub probe {
    Carp::croak("probe() is an abstract method. You must implement it in your class.");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober::Probe::Base

=head1 VERSION

version 0.17

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
