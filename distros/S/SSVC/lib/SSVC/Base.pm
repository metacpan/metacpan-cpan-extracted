package SSVC::Base;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Time::Piece;
use Carp ();

use overload '""' => 'to_vector_string', fallback => 1;

use constant METADATA        => +{};
use constant DECISION_POINTS => +{};
use constant DECISION_TREE   => +{};
use constant DECISION_PATH   => +[];
use constant VECTOR          => +[];

sub new {

    my ($class, %params) = @_;

    my %decision_points = $class->normalize_decision_points(%params);
    my %vector          = $class->decision_points_to_vector(%decision_points);
    my $decision        = undef;

    my $self = {decision_points => \%decision_points, vector => \%vector, decision => $decision};

    return bless $self, $class;

}

sub vector          { shift->{vector} }
sub decision_points { shift->{decision_points} }

sub compute {

    my ($self) = @_;

    my $key = join ':', map { $self->vector->{$_} } @{$self->DECISION_PATH};
    return $self->DECISION_TREE->{$key};

}

sub vector_value {
    my ($self, $name) = @_;
    return $self->{vector}->{$name};
}

sub decision_point_value {
    my ($self, $name) = @_;
    return $self->{decision_points}->{$name};
}

sub decision_point_enum {
    my ($self, $name) = @_;
    my @values = @{$self->DECISION_POINTS->{$name}->{values}};
    return [@values[grep { $_ % 2 } 0 .. @values]];
}

sub decision_point_labels {
    my ($self, $name) = @_;
    my %labels = @{$self->DECISION_POINTS->{$name}->{values}};
    return \%labels;
}

sub decision_point_codes {
    my ($self, $name) = @_;
    my %codes = reverse @{$self->DECISION_POINTS->{$name}->{values}};
    return \%codes;
}

sub decision_point_info {
    my ($self, $name) = @_;
    my $dp = $self->DECISION_POINTS->{$name};

    return {
        vector_name => $dp->{vector_name},
        label       => $dp->{label},
        definition  => $dp->{definition},
        enum        => $self->decision_point_enum($name),
        labels      => $self->decision_point_labels($name),
        codes       => $self->decision_point_codes($name),
    };
}

sub decision_points_to_vector {

    my ($self, %decision_points) = @_;

    my %output = ();

    foreach (keys %{$self->DECISION_POINTS}) {
        next unless $decision_points{$_};
        my $vector_name = $self->DECISION_POINTS->{$_}->{vector_name};
        $output{$vector_name} = $self->decision_point_codes($_)->{$decision_points{$_}};
    }

    return %output;

}

sub normalize_decision_points {

    my ($self, %params) = @_;

    my %normalized = ();

    foreach my $dp (keys %params) {

        my @allowed = @{$self->decision_point_enum($dp)};

        unless (grep { lc $params{$dp} eq $_ } @allowed) {
            Carp::croak "Unknown value for '$dp' (allowed: " . join(', ', @allowed) . ")";
        }

        $normalized{$dp} = lc $params{$dp};
    }

    return %normalized;

}


sub to_vector_string {

    my $self   = shift;
    my $prefix = 'SSVC';

    if (defined $self->METADATA->{key}) {
        $prefix = uc $self->METADATA->{key};
    }

    my $now     = Time::Piece->new->to_gmtime->datetime;
    my @vectors = (map { join ':', $_, $self->{vector}->{$_} || Carp::croak 'Missing metric' } @{$self->VECTOR});

    return join '/', "${prefix}v1", @vectors, "${now}.000Z";

}

sub TO_JSON { {} }

1;

__END__
=head1 NAME

SSVC::Base - Base class for SSVC methodology

=head1 SYNOPSIS

  package My::SSVC::Methodology {
    use parent 'SSVB::Base';
  }


=head1 DESCRIPTION

Base class for L<SSVC> methodology.

=head1 SEE ALSO

L<SSVC::CISA>, L<SSVC::CISA::BOD2604>, L<SSVC::CoordinatorPublication>, L<SSVC::CoordinatorTriage>, L<SSVC::Deployer>, L<SSVC::Supplier>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SSVC/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SSVC>

    git clone https://github.com/giterlizzi/perl-SSVC.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
