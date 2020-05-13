use utf8;

package SemanticWeb::Schema::ExercisePlan;

# ABSTRACT: Fitness-related activity designed for a specific health-related purpose

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::PhysicalActivity /;


use MooX::JSON_LD 'ExercisePlan';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has activity_duration => (
    is        => 'rw',
    predicate => '_has_activity_duration',
    json_ld   => 'activityDuration',
);



has activity_frequency => (
    is        => 'rw',
    predicate => '_has_activity_frequency',
    json_ld   => 'activityFrequency',
);



has additional_variable => (
    is        => 'rw',
    predicate => '_has_additional_variable',
    json_ld   => 'additionalVariable',
);



has exercise_type => (
    is        => 'rw',
    predicate => '_has_exercise_type',
    json_ld   => 'exerciseType',
);



has intensity => (
    is        => 'rw',
    predicate => '_has_intensity',
    json_ld   => 'intensity',
);



has repetitions => (
    is        => 'rw',
    predicate => '_has_repetitions',
    json_ld   => 'repetitions',
);



has rest_periods => (
    is        => 'rw',
    predicate => '_has_rest_periods',
    json_ld   => 'restPeriods',
);



has workload => (
    is        => 'rw',
    predicate => '_has_workload',
    json_ld   => 'workload',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ExercisePlan - Fitness-related activity designed for a specific health-related purpose

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

Fitness-related activity designed for a specific health-related purpose,
including defined exercise routines as well as activity prescribed by a
clinician.

=head1 ATTRIBUTES

=head2 C<activity_duration>

C<activityDuration>

Length of time to engage in the activity.

A activity_duration should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=back

=head2 C<_has_activity_duration>

A predicate for the L</activity_duration> attribute.

=head2 C<activity_frequency>

C<activityFrequency>

How often one should engage in the activity.

A activity_frequency should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<_has_activity_frequency>

A predicate for the L</activity_frequency> attribute.

=head2 C<additional_variable>

C<additionalVariable>

Any additional component of the exercise prescription that may need to be
articulated to the patient. This may include the order of exercises, the
number of repetitions of movement, quantitative distance, progressions over
time, etc.

A additional_variable should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_additional_variable>

A predicate for the L</additional_variable> attribute.

=head2 C<exercise_type>

C<exerciseType>

Type(s) of exercise or activity, such as strength training, flexibility
training, aerobics, cardiac rehabilitation, etc.

A exercise_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_exercise_type>

A predicate for the L</exercise_type> attribute.

=head2 C<intensity>

Quantitative measure gauging the degree of force involved in the exercise,
for example, heartbeats per minute. May include the velocity of the
movement.

A intensity should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<_has_intensity>

A predicate for the L</intensity> attribute.

=head2 C<repetitions>

Number of times one should repeat the activity.

A repetitions should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Num>

=back

=head2 C<_has_repetitions>

A predicate for the L</repetitions> attribute.

=head2 C<rest_periods>

C<restPeriods>

How often one should break from the activity.

A rest_periods should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=item C<Str>

=back

=head2 C<_has_rest_periods>

A predicate for the L</rest_periods> attribute.

=head2 C<workload>

Quantitative measure of the physiologic output of the exercise; also
referred to as energy expenditure.

A workload should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Energy']>

=item C<InstanceOf['SemanticWeb::Schema::QualitativeValue']>

=back

=head2 C<_has_workload>

A predicate for the L</workload> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PhysicalActivity>

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
