use utf8;

package SemanticWeb::Schema::EngineSpecification;

# ABSTRACT: Information about the engine of the vehicle

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'EngineSpecification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has engine_displacement => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'engineDisplacement',
);



has engine_power => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'enginePower',
);



has engine_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'engineType',
);



has fuel_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelType',
);



has torque => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'torque',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EngineSpecification - Information about the engine of the vehicle

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Information about the engine of the vehicle. A vehicle can have multiple
engines represented by multiple engine specification entities.

=head1 ATTRIBUTES

=head2 C<engine_displacement>

C<engineDisplacement>

=for html The volume swept by all of the pistons inside the cylinders of an internal
combustion engine in a single movement. <br/><br/> Typical unit code(s):
CMQ for cubic centimeter, LTR for liters, INQ for cubic inches * Note 1:
You can link to information about how the given value has been determined
using the <a class="localLink"
href="http://schema.org/valueReference">valueReference</a> property. * Note
2: You can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.

A engine_displacement should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<engine_power>

C<enginePower>

=for html The power of the vehicle's engine. Typical unit code(s): KWT for kilowatt,
BHP for brake horsepower, N12 for metric horsepower (PS, with 1 PS =
735,49875 W)<br/><br/> <ul> <li>Note 1: There are many different ways of
measuring an engine's power. For an overview, see <a
href="http://en.wikipedia.org/wiki/Horsepower#Engine_power_test_codes">http
://en.wikipedia.org/wiki/Horsepower#Engine<em>power</em>test_codes</a>.</li
> <li>Note 2: You can link to information about how the given value has
been determined using the <a class="localLink"
href="http://schema.org/valueReference">valueReference</a> property.</li>
<li>Note 3: You can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.</li>
</ul> 

A engine_power should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<engine_type>

C<engineType>

The type of engine or engines powering the vehicle.

A engine_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<fuel_type>

C<fuelType>

The type of fuel suitable for the engine or engines of the vehicle. If the
vehicle has only one engine, this property can be attached directly to the
vehicle.

A fuel_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<torque>

=for html The torque (turning force) of the vehicle's engine.<br/><br/> Typical unit
code(s): NU for newton metre (N m), F17 for pound-force per foot, or F48
for pound-force per inch<br/><br/> <ul> <li>Note 1: You can link to
information about how the given value has been determined (e.g. reference
RPM) using the <a class="localLink"
href="http://schema.org/valueReference">valueReference</a> property.</li>
<li>Note 2: You can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.</li>
</ul> 

A torque should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::StructuredValue>

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
