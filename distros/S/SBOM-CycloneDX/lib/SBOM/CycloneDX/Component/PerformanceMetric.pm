package SBOM::CycloneDX::Component::PerformanceMetric;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type                => (is => 'rw', isa => Str);
has value               => (is => 'rw', isa => Str);
has slice               => (is => 'rw', isa => Str);
has confidence_interval => (is => 'rw', isa => Str);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{type}               = $self->type                if $self->type;
    $json->{value}              = $self->value               if $self->value;
    $json->{slice}              = $self->slice               if $self->slice;
    $json->{confidenceInterval} = $self->confidence_interval if $self->confidence_interval;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::PerformanceMetric - Performance Metric

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::PerformanceMetric->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::PerformanceMetric> provides the model performance
metrics being reported. Examples may include accuracy, F1 score, precision,
top-3 error rates, MSC, etc.

=head2 METHODS

L<SBOM::CycloneDX::Component::PerformanceMetric> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::PerformanceMetric->new( %PARAMS )

Properties:

=over

=item * C<confidence_interval>, The confidence interval of the metric.

=item * C<slice>, The name of the slice this metric was computed on. By
default, assume this metric is not sliced.

=item * C<type>, The type of performance metric.

=item * C<value>, The value of the performance metric.

=back

=item $performance_metric->confidence_interval

=item $performance_metric->slice

=item $performance_metric->type

=item $performance_metric->value

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
