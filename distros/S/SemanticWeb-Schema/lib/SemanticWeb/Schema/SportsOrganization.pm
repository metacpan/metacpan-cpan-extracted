use utf8;

package SemanticWeb::Schema::SportsOrganization;

# ABSTRACT: Represents the collection of all sports organizations

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'SportsOrganization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has sport => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sport',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SportsOrganization - Represents the collection of all sports organizations

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

Represents the collection of all sports organizations, including sports
teams, governing bodies, and sports associations.

=head1 ATTRIBUTES

=head2 C<sport>

A type of sport (e.g. Baseball).

A sport should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
