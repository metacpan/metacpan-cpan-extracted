use utf8;

package SemanticWeb::Schema::ParentAudience;

# ABSTRACT: A set of characteristics describing parents

use Moo;

extends qw/ SemanticWeb::Schema::PeopleAudience /;


use MooX::JSON_LD 'ParentAudience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has child_max_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'childMaxAge',
);



has child_min_age => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'childMinAge',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ParentAudience - A set of characteristics describing parents

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A set of characteristics describing parents, who can be interested in
viewing some content.

=head1 ATTRIBUTES

=head2 C<child_max_age>

C<childMaxAge>

Maximal age of the child.

A child_max_age should be one of the following types:

=over

=item C<Num>

=back

=head2 C<child_min_age>

C<childMinAge>

Minimal age of the child.

A child_min_age should be one of the following types:

=over

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::PeopleAudience>

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
