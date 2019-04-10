use utf8;

package SemanticWeb::Schema::MedicalTestPanel;

# ABSTRACT: Any collection of tests commonly ordered together.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalTest /;


use MooX::JSON_LD 'MedicalTestPanel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has sub_test => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subTest',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalTestPanel - Any collection of tests commonly ordered together.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Any collection of tests commonly ordered together.

=head1 ATTRIBUTES

=head2 C<sub_test>

C<subTest>

A component test of the panel.

A sub_test should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

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
