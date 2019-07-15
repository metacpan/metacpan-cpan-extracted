use utf8;

package SemanticWeb::Schema::PeopleAudience;

# ABSTRACT: A set of characteristics belonging to people

use Moo;

extends qw/ SemanticWeb::Schema::Audience /;


use MooX::JSON_LD 'PeopleAudience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has health_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'healthCondition',
);



has required_gender => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiredGender',
);



has required_max_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiredMaxAge',
);



has required_min_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requiredMinAge',
);



has suggested_gender => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'suggestedGender',
);



has suggested_max_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'suggestedMaxAge',
);



has suggested_min_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'suggestedMinAge',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PeopleAudience - A set of characteristics belonging to people

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A set of characteristics belonging to people, e.g. who compose an item's
target audience.

=head1 ATTRIBUTES

=head2 C<health_condition>

C<healthCondition>

Specifying the health condition(s) of a patient, medical study, or other
target audience.

A health_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<required_gender>

C<requiredGender>

Audiences defined by a person's gender.

A required_gender should be one of the following types:

=over

=item C<Str>

=back

=head2 C<required_max_age>

C<requiredMaxAge>

Audiences defined by a person's maximum age.

A required_max_age should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<required_min_age>

C<requiredMinAge>

Audiences defined by a person's minimum age.

A required_min_age should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<suggested_gender>

C<suggestedGender>

The gender of the person or audience.

A suggested_gender should be one of the following types:

=over

=item C<Str>

=back

=head2 C<suggested_max_age>

C<suggestedMaxAge>

Maximal age recommended for viewing content.

A suggested_max_age should be one of the following types:

=over

=item C<Num>

=back

=head2 C<suggested_min_age>

C<suggestedMinAge>

Minimal age recommended for viewing content.

A suggested_min_age should be one of the following types:

=over

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Audience>

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
