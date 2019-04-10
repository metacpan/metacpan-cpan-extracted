use utf8;

package SemanticWeb::Schema::MobileApplication;

# ABSTRACT: A software application designed specifically to work well on a mobile device such as a telephone.

use Moo;

extends qw/ SemanticWeb::Schema::SoftwareApplication /;


use MooX::JSON_LD 'MobileApplication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has carrier_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'carrierRequirements',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MobileApplication - A software application designed specifically to work well on a mobile device such as a telephone.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A software application designed specifically to work well on a mobile
device such as a telephone.

=head1 ATTRIBUTES

=head2 C<carrier_requirements>

C<carrierRequirements>

Specifies specific carrier(s) requirements for the application (e.g. an
application may only work on a specific carrier network).

A carrier_requirements should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::SoftwareApplication>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
