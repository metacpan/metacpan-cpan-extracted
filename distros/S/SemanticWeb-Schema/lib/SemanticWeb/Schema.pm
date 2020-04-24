use utf8;

package SemanticWeb::Schema;

# ABSTRACT: Moo classes for http://schema.org/ classes

use v5.10.1;

use Moo;

use List::Util qw/ first /;
use MooX::JSON_LD 'base';
use Ref::Util qw/ is_blessed_ref is_plain_arrayref /;
use Types::Standard qw/ Str /;

use namespace::autoclean;

our $VERSION = 'v7.0.4';

# RECOMMEND PREREQ: aliased
# RECOMMEND PREREQ: Class::XSAccessor 1.18
# RECOMMEND PREREQ: Ref::Util::XS
# RECOMMEND PREREQ: Type::Tiny::XS


has id => (
    is        => 'rw',
    isa       => Str,
    predicate => 1,
    json_ld   => '@id',
);


around _build_context => sub { return 'http://schema.org/' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema - Moo classes for http://schema.org/ classes

=head1 VERSION

version v7.0.4

The version number of this distribution is based on the corresponding
version of schema classes.

=head1 SYNOPSIS

  use aliased 'SemanticWeb::Schema::Person' => 'Person';

  my $person = Person->new(
    name        => 'James Clerk Maxwell',
    birth_date  => '1831-06-13',
    birth_place => 'Edinburgh',
  );

  print $person->json_ld;

=head1 DESCRIPTION

This distribution contains Perl classes for L<https://schema.org>
semantic markup. These can be used to generate JSON-LD
to embed in websites.

This is a base class for the C<SemanticWeb::Schema> classes, which
were generated automatically from the following sources:

=over

=item L<https://schema.org/version/7.04/ext-auto.rdf>

=item L<https://schema.org/version/7.04/ext-bib.rdf>

=item L<https://schema.org/version/7.04/ext-health-lifesci.rdf>

=item L<https://schema.org/version/7.04/ext-meta.rdf>

=item L<https://schema.org/version/7.04/ext-pending.rdf>

=item L<https://schema.org/version/7.04/schema.rdf>

=back

=head1 ATTRIBUTES

=head2 C<id>

If this is set, it adds a C<@id> to the L</json_ld_data>.

=head2 C<context>

The context defaults to "http://schema.org/".

=head1 SEE ALSO

=over

=item L<Moo>

=item L<MooX::JSON_LD>

=item L<http://schema.org/>

=back

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

=head1 CONTRIBUTORS

=for stopwords Arikawa Takaya Mohammad S Anwar

=over 4

=item *

Arikawa Takaya <tky.c10.ver@gmail.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
