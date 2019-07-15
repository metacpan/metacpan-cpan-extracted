use utf8;

package SemanticWeb::Schema::DoseSchedule;

# ABSTRACT: A specific dosing schedule for a drug or supplement.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIntangible /;


use MooX::JSON_LD 'DoseSchedule';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has dose_unit => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'doseUnit',
);



has dose_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'doseValue',
);



has frequency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'frequency',
);



has target_population => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetPopulation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DoseSchedule - A specific dosing schedule for a drug or supplement.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A specific dosing schedule for a drug or supplement.

=head1 ATTRIBUTES

=head2 C<dose_unit>

C<doseUnit>

The unit of the dose, e.g. 'mg'.

A dose_unit should be one of the following types:

=over

=item C<Str>

=back

=head2 C<dose_value>

C<doseValue>

The value of the dose, e.g. 500.

A dose_value should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Num>

=back

=head2 C<frequency>

How often the dose is taken, e.g. 'daily'.

A frequency should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target_population>

C<targetPopulation>

Characteristics of the population for which this is intended, or which
typically uses it, e.g. 'adults'.

A target_population should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIntangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
