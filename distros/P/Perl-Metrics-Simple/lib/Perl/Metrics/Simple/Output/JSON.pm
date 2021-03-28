package Perl::Metrics::Simple::Output::JSON;

our $VERSION = 'v1.0.1';

use strict;
use warnings;

use parent qw(Perl::Metrics::Simple::Output);
use JSON::PP qw(encode_json);

sub make_report {
    my ($self) = @_;

    my $report = +{
        statistics => +{
            file_count        => $self->analysis()->file_count(),
            counts            => $self->make_counts(),
            subroutine_sizes  => $self->make_subroutine_size(),
            mccabe_complexity => $self->make_code_complexity(),
        },
        subs => $self->make_list_of_subs()->[1],
    };

    return encode_json($report);
}

sub make_counts {
    my ($self) = @_;

    my $analysis = $self->analysis();

    return +{
        total_code_lines       => $analysis->lines(),
        lines_of_non_sub_code  => $analysis->main_stats()->{'lines'},
        packages_found         => $analysis->package_count(),
        subs_and_methods_count => $analysis->sub_count(),
    };
}

sub make_subroutine_size {
    my ($self) = @_;

    my $stats = $self->analysis->summary_stats();

    return +{
        min                => $stats->{'sub_length'}->{min},
        max                => $stats->{'sub_length'}->{max},
        mean               => $stats->{'sub_length'}->{mean},
        standard_deviation => $stats->{'sub_length'}->{standard_deviation},
        median             => $stats->{'sub_length'}->{median},
    };
}

sub make_code_complexity {
    my ($self) = @_;

    return +{
        code_not_in_any_subroutine => $self->make_complexity_section('main_complexity'),
        sub_complexity             => $self->make_complexity_section('sub_complexity'),
    };
}

sub make_complexity_section {
    my ( $self, $key ) = @_;

    my $analysis = $self->analysis();

    return {
        min                => $analysis->summary_stats()->{$key}->{'min'},
        max                => $analysis->summary_stats()->{$key}->{'max'},
        mean               => $analysis->summary_stats()->{$key}->{'mean'},
        standard_deviation => $analysis->summary_stats()->{$key}->{'standard_deviation'},
        median             => $analysis->summary_stats()->{$key}->{'median'},
    };
}

