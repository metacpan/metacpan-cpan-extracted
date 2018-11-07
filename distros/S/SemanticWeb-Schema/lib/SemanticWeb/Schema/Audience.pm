use utf8;

package SemanticWeb::Schema::Audience;

# ABSTRACT: Intended audience for an item, i

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Audience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has audience_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'audienceType',
);



has geographic_area => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'geographicArea',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Audience - Intended audience for an item, i

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

Intended audience for an item, i.e. the group for whom the item was
created.

=head1 ATTRIBUTES

=head2 C<audience_type>

C<audienceType>

The target group associated with a given audience (e.g. veterans, car
owners, musicians, etc.).

A audience_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<geographic_area>

C<geographicArea>

The geographic area associated with the audience.

A geographic_area should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
