package Perl::Metrics::Simple::Output;

our $VERSION = '0.19';

use strict;
use warnings;

use Carp qw();

sub new {
    my ( $class, $analysis ) = @_;

    if ((! ref $analysis) && ($analysis->isa('Perl::Metrics::Simple::Analysis')) ) {
        Carp::confess('Did not pass a Perl::Metrics::Simple::Analysis object.');
    }
    
    my $self = bless {
        _analysis => $analysis,
    }, $class;

    return $self;
}

sub analysis {
    my ($self) = @_;
    return $self->{'_analysis'};
}

sub make_report {
    Carp::confess('Use one of the sub-classes, e.g. Perl::Metrics::Simple::Output::PlainText');
}

sub make_list_of_subs {
    my ($self) = @_;

    my $analysis = $self->analysis();

    my @main_from_each_file
        = map { $_->{main_stats} } @{ $analysis->file_stats() };
    my @sorted_all_subs = sort { $b->{'mccabe_complexity'} <=> $a->{'mccabe_complexity'} } ( @{ $analysis->subs() }, @main_from_each_file );

    return [ \@main_from_each_file, \@sorted_all_subs ];
}

1;    # Keep Perl happy, snuggy, and warm.

__END__

=pod

=head1 NAME

Perl::Metrics::Simple::Output - Base class for output classes

=head1 SYNOPSIS

Use one of the sub-classes, e.g. B<Perl::Metrics::Simple::Output::PlainText>

=cut
