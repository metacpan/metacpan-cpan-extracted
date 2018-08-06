package SemanticWeb::Schema::GovernmentBuilding;

# ABSTRACT: A government building.

use Moo;

extends qw/ SemanticWeb::Schema::CivicStructure /;


use MooX::JSON_LD 'GovernmentBuilding';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GovernmentBuilding - A government building.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A government building.

=head1 SEE ALSO

L<SemanticWeb::Schema::CivicStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
