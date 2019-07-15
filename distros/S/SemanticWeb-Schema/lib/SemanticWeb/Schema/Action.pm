use utf8;

package SemanticWeb::Schema::Action;

# ABSTRACT: An action performed by a direct agent and indirect participants upon a direct object

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'Action';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has action_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'actionStatus',
);



has agent => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'agent',
);



has end_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'endTime',
);



has error => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'error',
);



has instrument => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'instrument',
);



has location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'location',
);



has object => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'object',
);



has participant => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'participant',
);



has result => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'result',
);



has start_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'startTime',
);



has target => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'target',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Action - An action performed by a direct agent and indirect participants upon a direct object

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html An action performed by a direct agent and indirect participants upon a
direct object. Optionally happens at a location with the help of an
inanimate instrument. The execution of the action may produce a result.
Specific action sub-type documentation specifies the exact expectation of
each argument/role.<br/><br/> See also <a
href="http://blog.schema.org/2014/04/announcing-schemaorg-actions.html">blo
g post</a> and <a href="http://schema.org/docs/actions.html">Actions
overview document</a>.

=head1 ATTRIBUTES

=head2 C<action_status>

C<actionStatus>

Indicates the current disposition of the Action.

A action_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ActionStatusType']>

=back

=head2 C<agent>

=for html The direct performer or driver of the action (animate or inanimate). e.g.
<em>John</em> wrote a book.

A agent should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<end_time>

C<endTime>

=for html The endTime of something. For a reserved event or service (e.g.
FoodEstablishmentReservation), the time that it is expected to end. For
actions that span a period of time, when the action was performed. e.g.
John wrote a book from January to <em>December</em>. For media, including
audio and video, it's the time offset of the end of a clip within a larger
file.<br/><br/> Note that Event uses startDate/endDate instead of
startTime/endTime, even when describing dates with times. This situation
may be clarified in future revisions.

A end_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<error>

For failed actions, more information on the cause of the failure.

A error should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<instrument>

=for html The object that helped the agent perform the action. e.g. John wrote a book
with <em>a pen</em>.

A instrument should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<location>

The location of for example where the event is happening, an organization
is located, or where an action takes place.

A location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Place']>

=item C<InstanceOf['SemanticWeb::Schema::PostalAddress']>

=item C<Str>

=back

=head2 C<object>

=for html The object upon which the action is carried out, whose state is kept intact
or changed. Also known as the semantic roles patient, affected or undergoer
(which change their state) or theme (which doesn't). e.g. John read <em>a
book</em>.

A object should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<participant>

=for html Other co-agents that participated in the action indirectly. e.g. John wrote
a book with <em>Steve</em>.

A participant should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<result>

=for html The result produced in the action. e.g. John wrote <em>a book</em>.

A result should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<start_time>

C<startTime>

=for html The startTime of something. For a reserved event or service (e.g.
FoodEstablishmentReservation), the time that it is expected to start. For
actions that span a period of time, when the action was performed. e.g.
John wrote a book from <em>January</em> to December. For media, including
audio and video, it's the time offset of the start of a clip within a
larger file.<br/><br/> Note that Event uses startDate/endDate instead of
startTime/endTime, even when describing dates with times. This situation
may be clarified in future revisions.

A start_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target>

Indicates a target EntryPoint for an Action.

A target should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EntryPoint']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

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
