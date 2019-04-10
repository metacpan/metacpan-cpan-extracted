use utf8;

package SemanticWeb::Schema::DDxElement;

# ABSTRACT: An alternative

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIntangible /;


use MooX::JSON_LD 'DDxElement';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has diagnosis => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'diagnosis',
);



has distinguishing_sign => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'distinguishingSign',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DDxElement - An alternative

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

An alternative, closely-related condition typically considered later in the
differential diagnosis process along with the signs that are used to
distinguish it.

=head1 ATTRIBUTES

=head2 C<diagnosis>

One or more alternative conditions considered in the differential diagnosis
process as output of a diagnosis process.

A diagnosis should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<distinguishing_sign>

C<distinguishingSign>

One of a set of signs and symptoms that can be used to distinguish this
diagnosis from others in the differential diagnosis.

A distinguishing_sign should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSignOrSymptom']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIntangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
