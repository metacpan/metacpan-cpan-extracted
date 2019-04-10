use utf8;

package SemanticWeb::Schema::CourseInstance;

# ABSTRACT: An instance of a <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'CourseInstance';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has course_mode => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'courseMode',
);



has instructor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'instructor',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CourseInstance - An instance of a <a class="localLink" href="http://schema

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

=for html An instance of a <a class="localLink"
href="http://schema.org/Course">Course</a> which is distinct from other
instances because it is offered at a different time or location or through
different media or modes of study or to a specific section of students.

=head1 ATTRIBUTES

=head2 C<course_mode>

C<courseMode>

The medium or means of delivery of the course instance or the mode of
study, either as a text label (e.g. "online", "onsite" or "blended";
"synchronous" or "asynchronous"; "full-time" or "part-time") or as a URL
reference to a term from a controlled vocabulary (e.g.
https://ceds.ed.gov/element/001311#Asynchronous ).

A course_mode should be one of the following types:

=over

=item C<Str>

=back

=head2 C<instructor>

=for html A person assigned to instruct or provide instructional assistance for the
<a class="localLink"
href="http://schema.org/CourseInstance">CourseInstance</a>.

A instructor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
