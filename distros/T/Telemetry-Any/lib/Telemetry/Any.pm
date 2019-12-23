package Telemetry::Any;
use 5.008001;
use strict;
use warnings;

use Carp;

use base 'Devel::Timer';

our $VERSION = "0.07";

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

    my $report = $self->_report_headers(%args);
    $report .= $self->_report_data(%args);

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

sub _report_headers {
    my ( $self, %args ) = @_;

    my $report;

    if ( defined $args{format} && $args{format} eq 'table' ) {
        my $column = $args{collapse} ? "Count   " : "Interval    ";

        $report = ref($self) . ' Report -- Total time: ' . sprintf( '%.4f', $self->total_time() ) . " secs\n";
        $report .= "$column  Time    Percent\n";
        $report .= "----------------------------------------------\n";
    }

    return $report;
}

sub _report_data {
    my ( $self, %args ) = @_;

    my $report;

    my @records
        = $args{labels}
        ? ( $args{collapse} ? $self->any_labels_collapsed(%args) : $self->any_labels_detailed(%args) )
        : ( $args{collapse} ? $self->collapsed(%args)            : $self->detailed(%args) );

    if ( $args{collapse} ) {
        $report .= join "\n",
            map { sprintf( '%8s  %.4f  %5.2f%%  %s', $_->{count}, $_->{time}, $_->{percent}, $_->{label}, ) } @records;
    }
    else {
        $report .= join "\n", map {
            sprintf(
                '%04d -> %04d  %.4f  %5.2f%%  %s',
                $args{labels} ? $_->{from} : $_->{interval} - 1,
                $args{labels} ? $_->{to}   : $_->{interval},
                $_->{time}, $_->{percent}, $_->{label},
            )
        } @records;
    }

    return $report;
}

sub any_labels_detailed {
    my ( $self, %args ) = @_;

    my @labels      = _filter_input_labels( @{ $args{labels} } );
    my @count_pairs = $self->_define_count_pairs(@labels);

    return () if ( !scalar @count_pairs );

    my @sorted = sort { $b->{time} <=> $a->{time} } $self->_any_labels_detailed_records(@count_pairs);

    return @sorted;
}

sub any_labels_collapsed {
    my ( $self, %args ) = @_;

    my @detailed  = $self->any_labels_detailed(%args);
    my $collapsed = _calculate_any_labels_collapsed(@detailed);
    my $sort_by   = $args{sort_by} || 'time';

    return $self->_any_labels_collapsed_records( $collapsed, $sort_by );
}

sub _filter_input_labels {
    my (@labels) = @_;

    return grep { $_->[0] && $_->[1] && $_->[0] ne $_->[1] } @labels;
}

sub _define_count_pairs {
    my ( $self, @labels ) = @_;

    my @counts_pairs  = ();
    my @labels_counts = sort { $a <=> $b } keys %{ $self->{label} };

    foreach my $labels (@labels) {

        my @starts_counts = ();
        foreach my $count (@labels_counts) {

            if ( $self->{label}->{$count} eq $labels->[0] ) {
                push @starts_counts, $count;
            }
            elsif ( $self->{label}->{$count} eq $labels->[1] ) {
                my $start_count = pop @starts_counts;
                if ( defined $start_count ) {
                    push @counts_pairs, [ $start_count, $count ];
                }
            }
        }
    }

    return @counts_pairs;
}

sub _calculate_any_labels_collapsed {
    my (@records) = @_;

    my %collapsed;
    foreach my $i (@records) {
        my $label = $i->{label};
        my $time  = $i->{time};
        $collapsed{$label}{time} += $time;
        $collapsed{$label}{count}++;
    }

    return \%collapsed;
}

sub _any_labels_detailed_records {
    my ( $self, @count_pairs ) = @_;

    my @records = ();

    foreach my $counts (@count_pairs) {
        my $start_count  = $counts->[0];
        my $finish_count = $counts->[1];
        my $time         = Time::HiRes::tv_interval( $self->{times}->[$start_count], $self->{times}->[$finish_count] );
        my $record = {    ## no critic (NamingConventions::ProhibitAmbiguousNames
            from    => $start_count,
            to      => $finish_count,
            time    => sprintf( '%.6f', $time ),
            percent => sprintf( '%.2f', $time / $self->total_time() * 100 ),
            label   => sprintf( '%s -> %s', $self->{label}->{$start_count}, $self->{label}->{$finish_count} ),
        };
        push @records, $record;
    }

    return @records;
}

sub _any_labels_collapsed_records {
    my ( $self, $collapsed, $sort_by ) = @_;

    my @labels = sort { $collapsed->{$b}->{$sort_by} <=> $collapsed->{$a}->{$sort_by} } keys %$collapsed;

    my @records = ();
    foreach my $label (@labels) {

        my $record = {    ## no critic (NamingConventions::ProhibitAmbiguousNames
            count   => $collapsed->{$label}->{count},
            time    => sprintf( '%.6f', $collapsed->{$label}->{time} ),
            percent => sprintf( '%.2f', $collapsed->{$label}->{time} / $self->total_time() * 100 ),
            label   => $label,
        };
        push @records, $record;
    }

    return @records;
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

