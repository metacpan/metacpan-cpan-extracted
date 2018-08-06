package SemanticWeb::Schema;

# ABSTRACT: Moo classes for http://schema.org/ classes

use v5.10.1;

use Moo;

use List::Util qw/ first /;
use MooX::JSON_LD 'Class';
use Ref::Util qw/ is_blessed_ref is_plain_arrayref /;
use Types::Standard qw/ Str /;

use namespace::autoclean;

our $VERSION = 'v0.0.1';

# RECOMMEND PREREQ: aliased
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

version v0.0.1

=head1 SYNOPSIS

  use aliased 'SemanticWeb::Schema::Person' => 'Person';

  my $person = Person->new(
    name        => 'James Clerk Maxwell',
    birth_date  => '1831-06-13',
    birth_place => 'Edinburgh',
  );

  print $person->json_ld;

=head1 DESCRIPTION

This is a base class for the C<SemanticWeb::Schema> classes, which
were generated automatically from the following sources:

=over

=item L<http://schema.org/version/3.3/ext-meta.rdf>

=item L<http://schema.org/version/3.3/schema.rdf>

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

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
