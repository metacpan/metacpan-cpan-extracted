use utf8;

package SemanticWeb::Schema::ItemPage;

# ABSTRACT: A page devoted to a single item

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'ItemPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ItemPage - A page devoted to a single item

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A page devoted to a single item, such as a particular product or hotel.

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPage>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
