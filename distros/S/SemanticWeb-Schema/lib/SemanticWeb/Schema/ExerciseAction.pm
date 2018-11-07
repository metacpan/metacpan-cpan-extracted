use utf8;

package SemanticWeb::Schema::ExerciseAction;

# ABSTRACT: The act of participating in exertive activity for the purposes of improving health and fitness.

use Moo;

extends qw/ SemanticWeb::Schema::PlayAction /;


use MooX::JSON_LD 'ExerciseAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has course => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'course',
);



has distance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'distance',
);



has exercise_course => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'exerciseCourse',
);



has from_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fromLocation',
);



has opponent => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'opponent',
);



has sports_activity_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sportsActivityLocation',
);



has sports_event => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sportsEvent',
);



has sports_team => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sportsTeam',
);



has to_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'toLocation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ExerciseAction - The act of participating in exertive activity for the purposes of improving health and fitness.

=head1 VERSION

version v0.0.4

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

=head2 C<distance>

The distance travelled, e.g. exercising or travelling.

A distance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Distance']>

=back

=head2 C<exercise_course>

C<exerciseCourse>

A sub property of location. The course where this action was taken.

A exercise_course should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<from_location>

C<fromLocation>

A sub property of location. The original location of the object or the
agent before the action.

A from_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head2 C<opponent>

A sub property of participant. The opponent on this action.

A opponent should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<sports_activity_location>

C<sportsActivityLocation>

A sub property of location. The sports activity location where this action
occurred.

A sports_activity_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsActivityLocation']>

=back

=head2 C<sports_event>

C<sportsEvent>

A sub property of location. The sports event where this action occurred.

A sports_event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsEvent']>

=back

=head2 C<sports_team>

C<sportsTeam>

A sub property of participant. The sports team that participated on this
action.

A sports_team should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SportsTeam']>

=back

=head2 C<to_location>

C<toLocation>

A sub property of location. The final location of the object or the agent
after the action.

A to_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PlayAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
