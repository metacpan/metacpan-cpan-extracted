use utf8;

package SemanticWeb::Schema::Map;

# ABSTRACT: A map.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Map';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has map_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mapType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Map - A map.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A map.

=head1 ATTRIBUTES

=head2 C<map_type>

C<mapType>

Indicates the kind of Map, from the MapCategoryType Enumeration.

A map_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MapCategoryType']>

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
