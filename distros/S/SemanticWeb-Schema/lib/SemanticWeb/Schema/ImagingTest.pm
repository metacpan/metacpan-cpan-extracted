use utf8;

package SemanticWeb::Schema::ImagingTest;

# ABSTRACT: Any medical imaging modality typically used for diagnostic purposes.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalTest /;


use MooX::JSON_LD 'ImagingTest';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has imaging_technique => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'imagingTechnique',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ImagingTest - Any medical imaging modality typically used for diagnostic purposes.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Any medical imaging modality typically used for diagnostic purposes.

=head1 ATTRIBUTES

=head2 C<imaging_technique>

C<imagingTechnique>

Imaging technique used.

A imaging_technique should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalImagingTechnique']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalTest>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
