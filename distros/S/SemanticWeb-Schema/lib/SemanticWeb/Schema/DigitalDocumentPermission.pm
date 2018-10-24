use utf8;

package SemanticWeb::Schema::DigitalDocumentPermission;

# ABSTRACT: A permission for a particular person or group to access a particular file.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'DigitalDocumentPermission';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has grantee => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'grantee',
);



has permission_type => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'permissionType',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DigitalDocumentPermission - A permission for a particular person or group to access a particular file.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A permission for a particular person or group to access a particular file.

=head1 ATTRIBUTES

=head2 C<grantee>

The person, organization, contact point, or audience that has been granted
this permission.

A grantee should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<permission_type>

C<permissionType>

The type of permission granted the person, organization, or audience.

A permission_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DigitalDocumentPermissionType']>

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
