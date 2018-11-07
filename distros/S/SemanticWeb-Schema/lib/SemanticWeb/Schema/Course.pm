use utf8;

package SemanticWeb::Schema::Course;

# ABSTRACT: A description of an educational course which may be offered as distinct instances at which take place at different times or take place at different locations

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Course';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has course_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'courseCode',
);



has course_prerequisites => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'coursePrerequisites',
);



has has_course_instance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'hasCourseInstance',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Course - A description of an educational course which may be offered as distinct instances at which take place at different times or take place at different locations

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A description of an educational course which may be offered as distinct
instances at which take place at different times or take place at different
locations, or be offered through different media or modes of study. An
educational course is a sequence of one or more educational events and/or
creative works which aims to build knowledge, competence or ability of
learners.

=head1 ATTRIBUTES

=head2 C<course_code>

C<courseCode>

=for html The identifier for the <a class="localLink"
href="http://schema.org/Course">Course</a> used by the course <a
class="localLink" href="http://schema.org/provider">provider</a> (e.g.
CS101 or 6.001).

A course_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<course_prerequisites>

C<coursePrerequisites>

=for html Requirements for taking the Course. May be completion of another <a
class="localLink" href="http://schema.org/Course">Course</a> or a textual
description like "permission of instructor". Requirements may be a
pre-requisite competency, referenced using <a class="localLink"
href="http://schema.org/AlignmentObject">AlignmentObject</a>.

A course_prerequisites should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AlignmentObject']>

=item C<InstanceOf['SemanticWeb::Schema::Course']>

=item C<Str>

=back

=head2 C<has_course_instance>

C<hasCourseInstance>

An offering of the course at a specific time and place or through specific
media or mode of study or to a specific section of students.

A has_course_instance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CourseInstance']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
