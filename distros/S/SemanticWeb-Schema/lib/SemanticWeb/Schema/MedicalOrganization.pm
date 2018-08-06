package SemanticWeb::Schema::MedicalOrganization;

# ABSTRACT: A medical organization (physical or not)

use Moo;

extends qw/ SemanticWeb::Schema::Organization /;


use MooX::JSON_LD 'MedicalOrganization';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalOrganization - A medical organization (physical or not)

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A medical organization (physical or not), such as hospital, institution or
clinic.

=head1 SEE ALSO

L<SemanticWeb::Schema::Organization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
