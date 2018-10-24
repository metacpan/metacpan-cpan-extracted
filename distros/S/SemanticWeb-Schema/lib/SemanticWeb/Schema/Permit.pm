use utf8;

package SemanticWeb::Schema::Permit;

# ABSTRACT: A permit issued by an organization, e

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Permit';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has issued_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'issuedBy',
);



has issued_through => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'issuedThrough',
);



has permit_audience => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'permitAudience',
);



has valid_for => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validFor',
);



has valid_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validFrom',
);



has valid_in => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validIn',
);



has valid_until => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'validUntil',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Permit - A permit issued by an organization, e

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A permit issued by an organization, e.g. a parking pass.

=head1 ATTRIBUTES

=head2 C<issued_by>

C<issuedBy>

The organization issuing the ticket or permit.

A issued_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<issued_through>

C<issuedThrough>

The service through with the permit was granted.

A issued_through should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Service']>

=back

=head2 C<permit_audience>

C<permitAudience>

The target audience for this permit.

A permit_audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<valid_for>

C<validFor>

The time validity of the permit.

A valid_for should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<valid_from>

C<validFrom>

The date when the item becomes valid.

A valid_from should be one of the following types:

=over

=item C<Str>

=back

=head2 C<valid_in>

C<validIn>

The geographic area where the permit is valid.

A valid_in should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head2 C<valid_until>

C<validUntil>

The date when the item is no longer valid.

A valid_until should be one of the following types:

=over

=item C<Str>

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
