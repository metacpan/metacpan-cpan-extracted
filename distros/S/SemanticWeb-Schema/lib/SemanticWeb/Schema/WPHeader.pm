use utf8;

package SemanticWeb::Schema::WPHeader;

# ABSTRACT: The header section of the page.

use Moo;

extends qw/ SemanticWeb::Schema::WebPageElement /;


use MooX::JSON_LD 'WPHeader';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WPHeader - The header section of the page.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The header section of the page.

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPageElement>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
