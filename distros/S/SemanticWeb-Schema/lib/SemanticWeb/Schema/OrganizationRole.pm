use utf8;

package SemanticWeb::Schema::OrganizationRole;

# ABSTRACT: A subclass of Role used to describe roles within organizations.

use Moo;

extends qw/ SemanticWeb::Schema::Role /;


use MooX::JSON_LD 'OrganizationRole';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has numbered_position => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'numberedPosition',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::OrganizationRole - A subclass of Role used to describe roles within organizations.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A subclass of Role used to describe roles within organizations.

=head1 ATTRIBUTES

=head2 C<numbered_position>

C<numberedPosition>

A number associated with a role in an organization, for example, the number
on an athlete's jersey.

A numbered_position should be one of the following types:

=over

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Role>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
