use utf8;

package SemanticWeb::Schema::RestrictedDiet;

# ABSTRACT: A diet restricted to certain foods or preparations for cultural

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'RestrictedDiet';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RestrictedDiet - A diet restricted to certain foods or preparations for cultural

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A diet restricted to certain foods or preparations for cultural, religious,
health or lifestyle reasons.

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
