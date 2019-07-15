use utf8;

package SemanticWeb::Schema::MedicalContraindication;

# ABSTRACT: A condition or factor that serves as a reason to withhold a certain medical therapy

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalContraindication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalContraindication - A condition or factor that serves as a reason to withhold a certain medical therapy

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A condition or factor that serves as a reason to withhold a certain medical
therapy. Contraindications can be absolute (there are no reasonable
circumstances for undertaking a course of action) or relative (the patient
is at higher risk of complications, but that these risks may be outweighed
by other considerations or mitigated by other measures).

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
