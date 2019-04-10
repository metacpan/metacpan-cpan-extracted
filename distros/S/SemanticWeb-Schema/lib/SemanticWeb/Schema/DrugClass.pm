use utf8;

package SemanticWeb::Schema::DrugClass;

# ABSTRACT: A class of medical drugs, e

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEnumeration /;


use MooX::JSON_LD 'DrugClass';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


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

version v3.5.0

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

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
