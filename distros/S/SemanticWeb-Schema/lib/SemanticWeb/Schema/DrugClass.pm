use utf8;

package SemanticWeb::Schema::DrugClass;

# ABSTRACT: A class of medical drugs, e

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEnumeration /;


use MooX::JSON_LD 'DrugClass';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has drug => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'drug',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DrugClass - A class of medical drugs, e

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A class of medical drugs, e.g., statins. Classes can represent general
pharmacological class, common mechanisms of action, common physiological
effects, etc.

=head1 ATTRIBUTES

=head2 C<drug>

Specifying a drug or medicine used in a medication procedure

A drug should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEnumeration>

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
