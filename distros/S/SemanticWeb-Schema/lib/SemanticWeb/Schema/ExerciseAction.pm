use utf8;

package SemanticWeb::Schema::ExerciseAction;

# ABSTRACT: The act of participating in exertive activity for the purposes of improving health and fitness.

use Moo;

extends qw/ SemanticWeb::Schema::PlayAction /;


use MooX::JSON_LD 'ExerciseAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has course => (
    is        => 'rw',
    predicate => '_has_course',
    json_ld   => 'course',
);



has diet => (
    is        => 'rw',
    predicate => '_has_diet',
    json_ld   => 'diet',
);



has distance => (
    is        => 'rw',
    predicate => '_has_distance',
    json_ld   => 'distance',
);



has exercise_course => (
    is        => 'rw',
    predicate => '_has_exercise_course',
    json_ld   => 'exerciseCourse',
);



has exercise_plan => (
    is        => 'rw',
    predicate => '_has_exercise_plan',
    json_ld   => 'exercisePlan',
);



has exercise_related_diet => (
    is        => 'rw',
    predicate => '_has_exercise_related_diet',
    json_ld   => 'exerciseRelatedDiet',
);



has exercise_type => (
    is        => 'rw',
    predicate => '_has_exercise_type',
    json_ld   => 'exerciseType',
);



has from_location => (
    is        => 'rw',
    predicate => '_has_from_location',
    json_ld   => 'fromLocation',
);



has opponent => (
    is        => 'rw',
    predicate => '_has_opponent',
    json_ld   => 'opponent',
);



has sports_activity_location => (
    is        => 'rw',
    predicate => '_has_sports_activity_location',
    json_ld   => 'sportsActivityLocation',
);



has sports_event => (
    is        => 'rw',
    predicate => '_has_sports_event',
    json_ld   => 'sportsEvent',
);



has sports_team => (
    is        => 'rw',
    predicate => '_has_sports_team',
    json_ld   => 'sportsTeam',
);



has to_location => (
    is        => 'rw',
    predicate => '_has_to_location',
    json_ld   => 'toLocation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ExerciseAction - The act of participating in exertive activity for the purposes of improving health and fitness.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

The act of participating in exertive activity for the purposes of improving
health and fitness.

=head1 ATTRIBUTES

=head2 C<course>

A sub property of location. The course where this action was taken.

A course should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_course>

A predicate for the L</course> attribute.

=head2 C<diet>

A sub property of instrument. The diet used in this action.

A diet should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Diet']>

=back

=head2 C<_has_diet>

A predicate for the L</diet> attribute.

=head2 C<distance>

The distance travelled, e.g. exercising or travelling.

A distance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=back

=head2 C<_has_distance>

A predicate for the L</distance> attribute.

=head2 C<exercise_course>

C<exerciseCourse>

A sub property of location. The course where this action was taken.

A exercise_course should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_exercise_course>

A predicate for the L</exercise_course> attribute.

=head2 C<exercise_plan>

C<exercisePlan>

A sub property of instrument. The exercise plan used on this action.

A exercise_plan should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ExercisePlan']>

=back

=head2 C<_has_exercise_plan>

A predicate for the L</exercise_plan> attribute.

=head2 C<exercise_related_diet>

C<exerciseRelatedDiet>

A sub property of instrument. The diet used in this action.

A exercise_related_diet should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Diet']>

=back

=head2 C<_has_exercise_related_diet>

A predicate for the L</exercise_related_diet> attribute.

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

=head2 C<from_location>

C<fromLocation>

A sub property of location. The original location of the object or the
agent before the action.

A from_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_from_location>

A predicate for the L</from_location> attribute.

=head2 C<opponent>

A sub property of participant. The opponent on this action.

A opponent should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_opponent>

A predicate for the L</opponent> attribute.

=head2 C<sports_activity_location>

C<sportsActivityLocation>

A sub property of location. The sports activity location where this action
occurred.

A sports_activity_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsActivityLocation']>

=back

=head2 C<_has_sports_activity_location>

A predicate for the L</sports_activity_location> attribute.

=head2 C<sports_event>

C<sportsEvent>

A sub property of location. The sports event where this action occurred.

A sports_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsEvent']>

=back

=head2 C<_has_sports_event>

A predicate for the L</sports_event> attribute.

=head2 C<sports_team>

C<sportsTeam>

A sub property of participant. The sports team that participated on this
action.

A sports_team should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsTeam']>

=back

=head2 C<_has_sports_team>

A predicate for the L</sports_team> attribute.

=head2 C<to_location>

C<toLocation>

A sub property of location. The final location of the object or the agent
after the action.

A to_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<_has_to_location>

A predicate for the L</to_location> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::PlayAction>

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
