package Telemetry::Any;
use 5.008001;
use strict;
use warnings;

use Carp;

use base 'Devel::Timer';

our $VERSION = "0.06";

my $telemetry = __PACKAGE__->new();

sub import {
    my ( $class, $var ) = @_;

    return if !defined $var;

    my $saw_var;
    if ( $var =~ /^\$(\w+)/x ) {
        $saw_var = $1;
    }
    else {
        croak('Аrgument must be a variable');
    }

    my $caller = caller();

    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my $varname = "${caller}::${saw_var}";
    *$varname = \$telemetry;

    return;
}

## calculate total time (start time vs last time)
sub total_time {
    my ($self) = @_;

    return Time::HiRes::tv_interval( $self->{times}->[0], $self->{times}->[ $self->{count} - 1 ] );
}

sub report {
    my ( $self, %args ) = @_;

    my @records = $args{collapse} ? $self->collapsed(%args) : $self->detailed(%args);

    my $report;

    if ( defined $args{format} && $args{format} eq 'table' ) {
        $report .= ref($self) . ' Report -- Total time: ' . sprintf( '%.4f', $self->total_time() ) . " secs\n";
    }

    if ( $args{collapse} ) {
        if ( defined $args{format} && $args{format} eq 'table' ) {
            $report .= "Count     Time    Percent\n";
            $report .= "----------------------------------------------\n";
        }

        $report .= join "\n",
            map { sprintf( '%8s  %.4f  %5.2f%%  %s', $_->{count}, $_->{time}, $_->{percent}, $_->{label}, ) } @records;
    }
    else {
        if ( defined $args{format} && $args{format} eq 'table' ) {
            $report .= "Interval  Time    Percent\n";
            $report .= "----------------------------------------------\n";
        }

        $report .= join "\n", map {
            sprintf(
                '%02d -> %02d  %.4f  %5.2f%%  %s',
                $_->{interval} - 1,
                $_->{interval}, $_->{time}, $_->{percent}, $_->{label},
            )
        } @records;
    }

    return $report;
}

sub detailed {
    my ( $self, %args ) = @_;

    ## sort interval structure based on value

    @{ $self->{intervals} } = sort { $b->{value} <=> $a->{value} } @{ $self->{intervals} };

    ##
    ## report of each time space between marks
    ##

    my @records;

    for my $i ( @{ $self->{intervals} } ) {
        ## skip first time (to make an interval,
        ## compare the current time with the previous one)

        next if ( $i->{index} == 0 );

        my $record = {    ## no critic (NamingConventions::ProhibitAmbiguousNames
            interval => $i->{index},
            time     => sprintf( '%.6f', $i->{value} ),
            percent  => sprintf( '%.2f', $i->{value} / $self->total_time() * 100 ),
            label    => sprintf( '%s -> %s', $self->{label}->{ $i->{index} - 1 }, $self->{label}->{ $i->{index} } ),
        };

        push @records, $record;
    }

    return @records;
}

sub collapsed {
    my ( $self, %args ) = @_;

    $self->_calculate_collapsed;

    my $c       = $self->{collapsed};
    my $sort_by = $args{sort_by} || 'time';

    my @labels = sort { $c->{$b}->{$sort_by} <=> $c->{$a}->{$sort_by} } keys %$c;

    my @records;

    foreach my $label (@labels) {

        my $record = {    ## no critic (NamingConventions::ProhibitAmbiguousNames
            count   => $c->{$label}->{count},
            time    => sprintf( '%.6f', $c->{$label}->{time} ),
            percent => sprintf( '%.2f', $c->{$label}->{time} / $self->total_time() * 100 ),
            label   => $label,
        };

        push @records, $record;
    }

    return @records;
}

sub reset {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ($self) = @_;

    %{$self} = (
        times => [],
        count => 0,
        label => {},
    );

    return $self;
}

1;
__END__

=encoding utf-8

=head1 NAME

Telemetry::Any - It's new $module

=head1 SYNOPSIS

    use Telemetry::Any;

=head1 DESCRIPTION

Telemetry::Any is ...

=head1 LICENSE

Copyright (C) Mikhail Ivanov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mikhail Ivanov E<lt>m.ivanych@gmail.comE<gt>

=cut

