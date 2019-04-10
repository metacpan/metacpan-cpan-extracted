use utf8;

package SemanticWeb::Schema::EducationalOrganization;

# ABSTRACT: An educational organization.

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'EducationalOrganization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has alumni => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'alumni',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EducationalOrganization - An educational organization.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

An educational organization.

=head1 ATTRIBUTES

=head2 C<alumni>

Alumni of an organization.

A alumni should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
