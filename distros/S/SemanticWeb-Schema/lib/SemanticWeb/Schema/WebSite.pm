use utf8;

package SemanticWeb::Schema::WebSite;

# ABSTRACT: A WebSite is a set of related web pages and other items typically served from a single web domain and accessible via URLs.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'WebSite';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has issn => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'issn',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WebSite - A WebSite is a set of related web pages and other items typically served from a single web domain and accessible via URLs.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A WebSite is a set of related web pages and other items typically served
from a single web domain and accessible via URLs.

=head1 ATTRIBUTES

=head2 C<issn>

The International Standard Serial Number (ISSN) that identifies this serial
publication. You can repeat this property to identify different formats of,
or the linking ISSN (ISSN-L) for, this serial publication.

A issn should be one of the following types:

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
