use utf8;

package SemanticWeb::Schema::CDCPMDRecord;

# ABSTRACT: A CDCPMDRecord is a data structure representing a record in a CDC tabular data format used for hospital data reporting

use Moo;

extends qw/ SemanticWeb::Schema::StructuredValue /;


use MooX::JSON_LD 'CDCPMDRecord';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has cvd_collection_date => (
    is        => 'rw',
    predicate => '_has_cvd_collection_date',
    json_ld   => 'cvdCollectionDate',
);



has cvd_facility_county => (
    is        => 'rw',
    predicate => '_has_cvd_facility_county',
    json_ld   => 'cvdFacilityCounty',
);



has cvd_facility_id => (
    is        => 'rw',
    predicate => '_has_cvd_facility_id',
    json_ld   => 'cvdFacilityId',
);



has cvd_num_beds => (
    is        => 'rw',
    predicate => '_has_cvd_num_beds',
    json_ld   => 'cvdNumBeds',
);



has cvd_num_beds_occ => (
    is        => 'rw',
    predicate => '_has_cvd_num_beds_occ',
    json_ld   => 'cvdNumBedsOcc',
);



has cvd_num_c19died => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19died',
    json_ld   => 'cvdNumC19Died',
);



has cvd_num_c19ho_pats => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19ho_pats',
    json_ld   => 'cvdNumC19HOPats',
);



has cvd_num_c19hosp_pats => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19hosp_pats',
    json_ld   => 'cvdNumC19HospPats',
);



has cvd_num_c19mech_vent_pats => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19mech_vent_pats',
    json_ld   => 'cvdNumC19MechVentPats',
);



has cvd_num_c19of_mech_vent_pats => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19of_mech_vent_pats',
    json_ld   => 'cvdNumC19OFMechVentPats',
);



has cvd_num_c19overflow_pats => (
    is        => 'rw',
    predicate => '_has_cvd_num_c19overflow_pats',
    json_ld   => 'cvdNumC19OverflowPats',
);



has cvd_num_icu_beds => (
    is        => 'rw',
    predicate => '_has_cvd_num_icu_beds',
    json_ld   => 'cvdNumICUBeds',
);



has cvd_num_icu_beds_occ => (
    is        => 'rw',
    predicate => '_has_cvd_num_icu_beds_occ',
    json_ld   => 'cvdNumICUBedsOcc',
);



has cvd_num_tot_beds => (
    is        => 'rw',
    predicate => '_has_cvd_num_tot_beds',
    json_ld   => 'cvdNumTotBeds',
);



has cvd_num_vent => (
    is        => 'rw',
    predicate => '_has_cvd_num_vent',
    json_ld   => 'cvdNumVent',
);



has cvd_num_vent_use => (
    is        => 'rw',
    predicate => '_has_cvd_num_vent_use',
    json_ld   => 'cvdNumVentUse',
);



has date_posted => (
    is        => 'rw',
    predicate => '_has_date_posted',
    json_ld   => 'datePosted',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CDCPMDRecord - A CDCPMDRecord is a data structure representing a record in a CDC tabular data format used for hospital data reporting

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>A CDCPMDRecord is a data structure representing a record in a CDC
tabular data format used for hospital data reporting. See <a
href="/docs/cdc-covid.html">documentation</a> for details, and the linked
CDC materials for authoritative definitions used as the source here.<p>

=head1 ATTRIBUTES

=head2 C<cvd_collection_date>

C<cvdCollectionDate>

collectiondate - Date for which patient counts are reported.

A cvd_collection_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_cvd_collection_date>

A predicate for the L</cvd_collection_date> attribute.

=head2 C<cvd_facility_county>

C<cvdFacilityCounty>

=for html <p>Name of the County of the NHSN facility that this data record applies
to. Use <a class="localLink"
href="http://schema.org/cvdFacilityId">cvdFacilityId</a> to identify the
facility. To provide other details, <a class="localLink"
href="http://schema.org/healthcareReportingData">healthcareReportingData</a
> can be used on a <a class="localLink"
href="http://schema.org/Hospital">Hospital</a> entry.<p>

A cvd_facility_county should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_cvd_facility_county>

A predicate for the L</cvd_facility_county> attribute.

=head2 C<cvd_facility_id>

C<cvdFacilityId>

=for html <p>Identifier of the NHSN facility that this data record applies to. Use <a
class="localLink"
href="http://schema.org/cvdFacilityCounty">cvdFacilityCounty</a> to
indicate the county. To provide other details, <a class="localLink"
href="http://schema.org/healthcareReportingData">healthcareReportingData</a
> can be used on a <a class="localLink"
href="http://schema.org/Hospital">Hospital</a> entry.<p>

A cvd_facility_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_cvd_facility_id>

A predicate for the L</cvd_facility_id> attribute.

=head2 C<cvd_num_beds>

C<cvdNumBeds>

numbeds - HOSPITAL INPATIENT BEDS: Inpatient beds, including all staffed,
licensed, and overflow (surge) beds used for inpatients.

A cvd_num_beds should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_beds>

A predicate for the L</cvd_num_beds> attribute.

=head2 C<cvd_num_beds_occ>

C<cvdNumBedsOcc>

numbedsocc - HOSPITAL INPATIENT BED OCCUPANCY: Total number of staffed
inpatient beds that are occupied.

A cvd_num_beds_occ should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_beds_occ>

A predicate for the L</cvd_num_beds_occ> attribute.

=head2 C<cvd_num_c19died>

C<cvdNumC19Died>

numc19died - DEATHS: Patients with suspected or confirmed COVID-19 who died
in the hospital, ED, or any overflow location.

A cvd_num_c19died should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19died>

A predicate for the L</cvd_num_c19died> attribute.

=head2 C<cvd_num_c19ho_pats>

C<cvdNumC19HOPats>

numc19hopats - HOSPITAL ONSET: Patients hospitalized in an NHSN inpatient
care location with onset of suspected or confirmed COVID-19 14 or more days
after hospitalization.

A cvd_num_c19ho_pats should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19ho_pats>

A predicate for the L</cvd_num_c19ho_pats> attribute.

=head2 C<cvd_num_c19hosp_pats>

C<cvdNumC19HospPats>

numc19hosppats - HOSPITALIZED: Patients currently hospitalized in an
inpatient care location who have suspected or confirmed COVID-19.

A cvd_num_c19hosp_pats should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19hosp_pats>

A predicate for the L</cvd_num_c19hosp_pats> attribute.

=head2 C<cvd_num_c19mech_vent_pats>

C<cvdNumC19MechVentPats>

numc19mechventpats - HOSPITALIZED and VENTILATED: Patients hospitalized in
an NHSN inpatient care location who have suspected or confirmed COVID-19
and are on a mechanical ventilator.

A cvd_num_c19mech_vent_pats should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19mech_vent_pats>

A predicate for the L</cvd_num_c19mech_vent_pats> attribute.

=head2 C<cvd_num_c19of_mech_vent_pats>

C<cvdNumC19OFMechVentPats>

numc19ofmechventpats - ED/OVERFLOW and VENTILATED: Patients with suspected
or confirmed COVID-19 who are in the ED or any overflow location awaiting
an inpatient bed and on a mechanical ventilator.

A cvd_num_c19of_mech_vent_pats should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19of_mech_vent_pats>

A predicate for the L</cvd_num_c19of_mech_vent_pats> attribute.

=head2 C<cvd_num_c19overflow_pats>

C<cvdNumC19OverflowPats>

numc19overflowpats - ED/OVERFLOW: Patients with suspected or confirmed
COVID-19 who are in the ED or any overflow location awaiting an inpatient
bed.

A cvd_num_c19overflow_pats should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_c19overflow_pats>

A predicate for the L</cvd_num_c19overflow_pats> attribute.

=head2 C<cvd_num_icu_beds>

C<cvdNumICUBeds>

numicubeds - ICU BEDS: Total number of staffed inpatient intensive care
unit (ICU) beds.

A cvd_num_icu_beds should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_icu_beds>

A predicate for the L</cvd_num_icu_beds> attribute.

=head2 C<cvd_num_icu_beds_occ>

C<cvdNumICUBedsOcc>

numicubedsocc - ICU BED OCCUPANCY: Total number of staffed inpatient ICU
beds that are occupied.

A cvd_num_icu_beds_occ should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_icu_beds_occ>

A predicate for the L</cvd_num_icu_beds_occ> attribute.

=head2 C<cvd_num_tot_beds>

C<cvdNumTotBeds>

numtotbeds - ALL HOSPITAL BEDS: Total number of all Inpatient and
outpatient beds, including all staffed,ICU, licensed, and overflow (surge)
beds used for inpatients or outpatients.

A cvd_num_tot_beds should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_tot_beds>

A predicate for the L</cvd_num_tot_beds> attribute.

=head2 C<cvd_num_vent>

C<cvdNumVent>

numvent - MECHANICAL VENTILATORS: Total number of ventilators available.

A cvd_num_vent should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_vent>

A predicate for the L</cvd_num_vent> attribute.

=head2 C<cvd_num_vent_use>

C<cvdNumVentUse>

numventuse - MECHANICAL VENTILATORS IN USE: Total number of ventilators in
use.

A cvd_num_vent_use should be one of the following types:

=over

=item C<Num>

=back

=head2 C<_has_cvd_num_vent_use>

A predicate for the L</cvd_num_vent_use> attribute.

=head2 C<date_posted>

C<datePosted>

Publication date of an online listing.

A date_posted should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_date_posted>

A predicate for the L</date_posted> attribute.

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
