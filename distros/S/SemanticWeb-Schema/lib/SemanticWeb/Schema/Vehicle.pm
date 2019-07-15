use utf8;

package SemanticWeb::Schema::Vehicle;

# ABSTRACT: A vehicle is a device that is designed or used to transport people or cargo over land

use Moo;

extends qw/ SemanticWeb::Schema::Product /;


use MooX::JSON_LD 'Vehicle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has acceleration_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'accelerationTime',
);



has body_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bodyType',
);



has cargo_volume => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'cargoVolume',
);



has date_vehicle_first_registered => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dateVehicleFirstRegistered',
);



has drive_wheel_configuration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'driveWheelConfiguration',
);



has emissions_co2 => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'emissionsCO2',
);



has fuel_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelCapacity',
);



has fuel_consumption => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelConsumption',
);



has fuel_efficiency => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelEfficiency',
);



has fuel_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fuelType',
);



has known_vehicle_damages => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'knownVehicleDamages',
);



has meets_emission_standard => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'meetsEmissionStandard',
);



has mileage_from_odometer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mileageFromOdometer',
);



has model_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'modelDate',
);



has number_of_airbags => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfAirbags',
);



has number_of_axles => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfAxles',
);



has number_of_doors => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfDoors',
);



has number_of_forward_gears => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfForwardGears',
);



has number_of_previous_owners => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberOfPreviousOwners',
);



has payload => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'payload',
);



has production_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'productionDate',
);



has purchase_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'purchaseDate',
);



has seating_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seatingCapacity',
);



has speed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'speed',
);



has steering_position => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'steeringPosition',
);



has tongue_weight => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'tongueWeight',
);



has trailer_weight => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trailerWeight',
);



has vehicle_configuration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleConfiguration',
);



has vehicle_engine => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleEngine',
);



has vehicle_identification_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleIdentificationNumber',
);



has vehicle_interior_color => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleInteriorColor',
);



has vehicle_interior_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleInteriorType',
);



has vehicle_model_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleModelDate',
);



has vehicle_seating_capacity => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleSeatingCapacity',
);



has vehicle_special_usage => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleSpecialUsage',
);



has vehicle_transmission => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'vehicleTransmission',
);



has weight_total => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'weightTotal',
);



has wheelbase => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'wheelbase',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Vehicle - A vehicle is a device that is designed or used to transport people or cargo over land

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A vehicle is a device that is designed or used to transport people or cargo
over land, water, air, or through space.

=head1 ATTRIBUTES

=head2 C<acceleration_time>

C<accelerationTime>

=for html The time needed to accelerate the vehicle from a given start velocity to a
given target velocity.<br/><br/> Typical unit code(s): SEC for
seconds<br/><br/> <ul> <li>Note: There are unfortunately no standard unit
codes for seconds/0..100 km/h or seconds/0..60 mph. Simply use "SEC" for
seconds and indicate the velocities in the <a class="localLink"
href="http://schema.org/name">name</a> of the <a class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a>, or use <a
class="localLink"
href="http://schema.org/valueReference">valueReference</a> with a <a
class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> of 0..60
mph or 0..100 km/h to specify the reference speeds.</li> </ul> 

A acceleration_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<body_type>

C<bodyType>

Indicates the design and body style of the vehicle (e.g. station wagon,
hatchback, etc.).

A body_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<cargo_volume>

C<cargoVolume>

=for html The available volume for cargo or luggage. For automobiles, this is usually
the trunk volume.<br/><br/> Typical unit code(s): LTR for liters, FTQ for
cubic foot/feet<br/><br/> Note: You can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.

A cargo_volume should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<date_vehicle_first_registered>

C<dateVehicleFirstRegistered>

The date of the first registration of the vehicle with the respective
public authorities.

A date_vehicle_first_registered should be one of the following types:

=over

=item C<Str>

=back

=head2 C<drive_wheel_configuration>

C<driveWheelConfiguration>

The drive wheel configuration, i.e. which roadwheels will receive torque
from the vehicle's engine via the drivetrain.

A drive_wheel_configuration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DriveWheelConfigurationValue']>

=item C<Str>

=back

=head2 C<emissions_co2>

C<emissionsCO2>

The CO2 emissions in g/km. When used in combination with a
QuantitativeValue, put "g/km" into the unitText property of that value,
since there is no UN/CEFACT Common Code for "g/km".

A emissions_co2 should be one of the following types:

=over

=item C<Num>

=back

=head2 C<fuel_capacity>

C<fuelCapacity>

=for html The capacity of the fuel tank or in the case of electric cars, the battery.
If there are multiple components for storage, this should indicate the
total of all storage of the same type.<br/><br/> Typical unit code(s): LTR
for liters, GLL of US gallons, GLI for UK / imperial gallons, AMH for
ampere-hours (for electrical vehicles).

A fuel_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<fuel_consumption>

C<fuelConsumption>

=for html The amount of fuel consumed for traveling a particular distance or temporal
duration with the given vehicle (e.g. liters per 100 km).<br/><br/> <ul>
<li>Note 1: There are unfortunately no standard unit codes for liters per
100 km. Use <a class="localLink"
href="http://schema.org/unitText">unitText</a> to indicate the unit of
measurement, e.g. L/100 km.</li> <li>Note 2: There are two ways of
indicating the fuel consumption, <a class="localLink"
href="http://schema.org/fuelConsumption">fuelConsumption</a> (e.g. 8 liters
per 100 km) and <a class="localLink"
href="http://schema.org/fuelEfficiency">fuelEfficiency</a> (e.g. 30 miles
per gallon). They are reciprocal.</li> <li>Note 3: Often, the absolute
value is useful only when related to driving speed ("at 80 km/h") or usage
pattern ("city traffic"). You can use <a class="localLink"
href="http://schema.org/valueReference">valueReference</a> to link the
value for the fuel consumption to another value.</li> </ul> 

A fuel_consumption should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<fuel_efficiency>

C<fuelEfficiency>

=for html The distance traveled per unit of fuel used; most commonly miles per gallon
(mpg) or kilometers per liter (km/L).<br/><br/> <ul> <li>Note 1: There are
unfortunately no standard unit codes for miles per gallon or kilometers per
liter. Use <a class="localLink"
href="http://schema.org/unitText">unitText</a> to indicate the unit of
measurement, e.g. mpg or km/L.</li> <li>Note 2: There are two ways of
indicating the fuel consumption, <a class="localLink"
href="http://schema.org/fuelConsumption">fuelConsumption</a> (e.g. 8 liters
per 100 km) and <a class="localLink"
href="http://schema.org/fuelEfficiency">fuelEfficiency</a> (e.g. 30 miles
per gallon). They are reciprocal.</li> <li>Note 3: Often, the absolute
value is useful only when related to driving speed ("at 80 km/h") or usage
pattern ("city traffic"). You can use <a class="localLink"
href="http://schema.org/valueReference">valueReference</a> to link the
value for the fuel economy to another value.</li> </ul> 

A fuel_efficiency should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

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

=head2 C<known_vehicle_damages>

C<knownVehicleDamages>

A textual description of known damages, both repaired and unrepaired.

A known_vehicle_damages should be one of the following types:

=over

=item C<Str>

=back

=head2 C<meets_emission_standard>

C<meetsEmissionStandard>

Indicates that the vehicle meets the respective emission standard.

A meets_emission_standard should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<mileage_from_odometer>

C<mileageFromOdometer>

=for html The total distance travelled by the particular vehicle since its initial
production, as read from its odometer.<br/><br/> Typical unit code(s): KMT
for kilometers, SMI for statute miles

A mileage_from_odometer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<model_date>

C<modelDate>

The release date of a vehicle model (often used to differentiate versions
of the same make and model).

A model_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<number_of_airbags>

C<numberOfAirbags>

The number or type of airbags in the vehicle.

A number_of_airbags should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<number_of_axles>

C<numberOfAxles>

=for html The number of axles.<br/><br/> Typical unit code(s): C62

A number_of_axles should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<number_of_doors>

C<numberOfDoors>

=for html The number of doors.<br/><br/> Typical unit code(s): C62

A number_of_doors should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<number_of_forward_gears>

C<numberOfForwardGears>

=for html The total number of forward gears available for the transmission system of
the vehicle.<br/><br/> Typical unit code(s): C62

A number_of_forward_gears should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<number_of_previous_owners>

C<numberOfPreviousOwners>

=for html The number of owners of the vehicle, including the current one.<br/><br/>
Typical unit code(s): C62

A number_of_previous_owners should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<payload>

=for html The permitted weight of passengers and cargo, EXCLUDING the weight of the
empty vehicle.<br/><br/> Typical unit code(s): KGM for kilogram, LBR for
pound<br/><br/> <ul> <li>Note 1: Many databases specify the permitted TOTAL
weight instead, which is the sum of <a class="localLink"
href="http://schema.org/weight">weight</a> and <a class="localLink"
href="http://schema.org/payload">payload</a></li> <li>Note 2: You can
indicate additional information in the <a class="localLink"
href="http://schema.org/name">name</a> of the <a class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> node.</li>
<li>Note 3: You may also link to a <a class="localLink"
href="http://schema.org/QualitativeValue">QualitativeValue</a> node that
provides additional information using <a class="localLink"
href="http://schema.org/valueReference">valueReference</a>.</li> <li>Note
4: Note that you can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.</li>
</ul> 

A payload should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<production_date>

C<productionDate>

The date of production of the item, e.g. vehicle.

A production_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<purchase_date>

C<purchaseDate>

The date the item e.g. vehicle was purchased by the current owner.

A purchase_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<seating_capacity>

C<seatingCapacity>

=for html The number of persons that can be seated (e.g. in a vehicle), both in terms
of the physical space available, and in terms of limitations set by
law.<br/><br/> Typical unit code(s): C62 for persons

A seating_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<speed>

=for html The speed range of the vehicle. If the vehicle is powered by an engine, the
upper limit of the speed range (indicated by <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> should be the maximum speed
achievable under regular conditions.<br/><br/> Typical unit code(s): KMH
for km/h, HM for mile per hour (0.447 04 m/s), KNT for knot<br/><br/> *Note
1: Use <a class="localLink" href="http://schema.org/minValue">minValue</a>
and <a class="localLink" href="http://schema.org/maxValue">maxValue</a> to
indicate the range. Typically, the minimal value is zero. * Note 2: There
are many different ways of measuring the speed range. You can link to
information about how the given value has been determined using the <a
class="localLink"
href="http://schema.org/valueReference">valueReference</a> property.

A speed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<steering_position>

C<steeringPosition>

The position of the steering wheel or similar device (mostly for cars).

A steering_position should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SteeringPositionValue']>

=back

=head2 C<tongue_weight>

C<tongueWeight>

=for html The permitted vertical load (TWR) of a trailer attached to the vehicle.
Also referred to as Tongue Load Rating (TLR) or Vertical Load Rating
(VLR)<br/><br/> Typical unit code(s): KGM for kilogram, LBR for
pound<br/><br/> <ul> <li>Note 1: You can indicate additional information in
the <a class="localLink" href="http://schema.org/name">name</a> of the <a
class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> node.</li>
<li>Note 2: You may also link to a <a class="localLink"
href="http://schema.org/QualitativeValue">QualitativeValue</a> node that
provides additional information using <a class="localLink"
href="http://schema.org/valueReference">valueReference</a>.</li> <li>Note
3: Note that you can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.</li>
</ul> 

A tongue_weight should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<trailer_weight>

C<trailerWeight>

=for html The permitted weight of a trailer attached to the vehicle.<br/><br/>
Typical unit code(s): KGM for kilogram, LBR for pound * Note 1: You can
indicate additional information in the <a class="localLink"
href="http://schema.org/name">name</a> of the <a class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> node. *
Note 2: You may also link to a <a class="localLink"
href="http://schema.org/QualitativeValue">QualitativeValue</a> node that
provides additional information using <a class="localLink"
href="http://schema.org/valueReference">valueReference</a>. * Note 3: Note
that you can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.

A trailer_weight should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<vehicle_configuration>

C<vehicleConfiguration>

A short text indicating the configuration of the vehicle, e.g. '5dr
hatchback ST 2.5 MT 225 hp' or 'limited edition'.

A vehicle_configuration should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vehicle_engine>

C<vehicleEngine>

Information about the engine or engines of the vehicle.

A vehicle_engine should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EngineSpecification']>

=back

=head2 C<vehicle_identification_number>

C<vehicleIdentificationNumber>

The Vehicle Identification Number (VIN) is a unique serial number used by
the automotive industry to identify individual motor vehicles.

A vehicle_identification_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vehicle_interior_color>

C<vehicleInteriorColor>

The color or color combination of the interior of the vehicle.

A vehicle_interior_color should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vehicle_interior_type>

C<vehicleInteriorType>

The type or material of the interior of the vehicle (e.g. synthetic fabric,
leather, wood, etc.). While most interior types are characterized by the
material used, an interior type can also be based on vehicle usage or
target audience.

A vehicle_interior_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vehicle_model_date>

C<vehicleModelDate>

The release date of a vehicle model (often used to differentiate versions
of the same make and model).

A vehicle_model_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<vehicle_seating_capacity>

C<vehicleSeatingCapacity>

=for html The number of passengers that can be seated in the vehicle, both in terms
of the physical space available, and in terms of limitations set by
law.<br/><br/> Typical unit code(s): C62 for persons.

A vehicle_seating_capacity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=item C<Num>

=back

=head2 C<vehicle_special_usage>

C<vehicleSpecialUsage>

Indicates whether the vehicle has been used for special purposes, like
commercial rental, driving school, or as a taxi. The legislation in many
countries requires this information to be revealed when offering a car for
sale.

A vehicle_special_usage should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CarUsageType']>

=item C<Str>

=back

=head2 C<vehicle_transmission>

C<vehicleTransmission>

The type of component used for transmitting the power from a rotating power
source to the wheels or other relevant component(s) ("gearbox" for cars).

A vehicle_transmission should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<weight_total>

C<weightTotal>

=for html The permitted total weight of the loaded vehicle, including passengers and
cargo and the weight of the empty vehicle.<br/><br/> Typical unit code(s):
KGM for kilogram, LBR for pound<br/><br/> <ul> <li>Note 1: You can indicate
additional information in the <a class="localLink"
href="http://schema.org/name">name</a> of the <a class="localLink"
href="http://schema.org/QuantitativeValue">QuantitativeValue</a> node.</li>
<li>Note 2: You may also link to a <a class="localLink"
href="http://schema.org/QualitativeValue">QualitativeValue</a> node that
provides additional information using <a class="localLink"
href="http://schema.org/valueReference">valueReference</a>.</li> <li>Note
3: Note that you can use <a class="localLink"
href="http://schema.org/minValue">minValue</a> and <a class="localLink"
href="http://schema.org/maxValue">maxValue</a> to indicate ranges.</li>
</ul> 

A weight_total should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head2 C<wheelbase>

=for html The distance between the centers of the front and rear wheels.<br/><br/>
Typical unit code(s): CMT for centimeters, MTR for meters, INH for inches,
FOT for foot/feet

A wheelbase should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QuantitativeValue']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Product>

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
