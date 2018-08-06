package SemanticWeb::Schema::TechArticle;

# ABSTRACT: A technical article - Example: How-to (task) topics

use Moo;

extends qw/ SemanticWeb::Schema::Article /;


use MooX::JSON_LD 'TechArticle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has dependencies => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dependencies',
);



has proficiency_level => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'proficiencyLevel',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TechArticle - A technical article - Example: How-to (task) topics

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A technical article - Example: How-to (task) topics, step-by-step,
procedural troubleshooting, specifications, etc.

=head1 ATTRIBUTES

=head2 C<dependencies>

Prerequisites needed to fulfill steps in article.

A dependencies should be one of the following types:

=over

=item C<Str>

=back

=head2 C<proficiency_level>

C<proficiencyLevel>

Proficiency needed for this content; expected values: 'Beginner', 'Expert'.

A proficiency_level should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Article>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
