package SBOM::CycloneDX::Component::ConfidenceInterval;

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

has lower_bound => (is => 'rw', isa => Str);
has upper_bound => (is => 'rw', isa => Str);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{lowerBound} = $self->lower_bound if $self->lower_bound;
    $json->{upperBound} = $self->upper_bound if $self->upper_bound;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component::ConfidenceInterval - Confidence Interval

=head1 SYNOPSIS

    SBOM::CycloneDX::Component::ConfidenceInterval->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component::ConfidenceInterval> The confidence interval
of the metric.

=head2 METHODS

L<SBOM::CycloneDX::Component::ConfidenceInterval> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component::ConfidenceInterval->new( %PARAMS )

Properties:

=over

=item * C<lower_bound>, The lower bound of the confidence interval.

=item * C<upper_bound>, The upper bound of the confidence interval.

=back

=item $confidence_interval->lower_bound

=item $confidence_interval->upper_bound

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
