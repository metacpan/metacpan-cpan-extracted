use utf8;

package SemanticWeb::Schema::MedicalDevicePurpose;

# ABSTRACT: Categories of medical devices

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEnumeration /;


use MooX::JSON_LD 'MedicalDevicePurpose';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalDevicePurpose - Categories of medical devices

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Categories of medical devices, organized by the purpose or intended use of
the device.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEnumeration>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
