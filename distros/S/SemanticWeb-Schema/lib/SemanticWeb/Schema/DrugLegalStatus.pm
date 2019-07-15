use utf8;

package SemanticWeb::Schema::DrugLegalStatus;

# ABSTRACT: The legal availability status of a medical drug.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIntangible /;


use MooX::JSON_LD 'DrugLegalStatus';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has applicable_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'applicableLocation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DrugLegalStatus - The legal availability status of a medical drug.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The legal availability status of a medical drug.

=head1 ATTRIBUTES

=head2 C<applicable_location>

C<applicableLocation>

The location in which the status applies.

A applicable_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIntangible>

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
