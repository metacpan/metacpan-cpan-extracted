use utf8;

package SemanticWeb::Schema::Thesis;

# ABSTRACT: A thesis or dissertation document submitted in support of candidature for an academic degree or professional qualification.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Thesis';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


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

version v3.5.0

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

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
