use utf8;

package SemanticWeb::Schema::ItemListOrderType;

# ABSTRACT: Enumerated for values for itemListOrder for indicating how an ordered ItemList is organized.

use Moo;

extends qw/ SemanticWeb::Schema::Enumeration /;


use MooX::JSON_LD 'ItemListOrderType';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ItemListOrderType - Enumerated for values for itemListOrder for indicating how an ordered ItemList is organized.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Enumerated for values for itemListOrder for indicating how an ordered
ItemList is organized.

=head1 SEE ALSO

L<SemanticWeb::Schema::Enumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
