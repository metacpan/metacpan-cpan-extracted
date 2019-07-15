use utf8;

package SemanticWeb::Schema::Thesis;

# ABSTRACT: A thesis or dissertation document submitted in support of candidature for an academic degree or professional qualification.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Thesis';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has in_support_of => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'inSupportOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Thesis - A thesis or dissertation document submitted in support of candidature for an academic degree or professional qualification.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A thesis or dissertation document submitted in support of candidature for
an academic degree or professional qualification.

=head1 ATTRIBUTES

=head2 C<in_support_of>

C<inSupportOf>

Qualification, candidature, degree, application that Thesis supports.

A in_support_of should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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
