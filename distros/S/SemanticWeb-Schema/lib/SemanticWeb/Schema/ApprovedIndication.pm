use utf8;

package SemanticWeb::Schema::ApprovedIndication;

# ABSTRACT: An indication for a medical therapy that has been formally specified or approved by a regulatory body that regulates use of the therapy; for example

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIndication /;


use MooX::JSON_LD 'ApprovedIndication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ApprovedIndication - An indication for a medical therapy that has been formally specified or approved by a regulatory body that regulates use of the therapy; for example

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

An indication for a medical therapy that has been formally specified or
approved by a regulatory body that regulates use of the therapy; for
example, the US FDA approves indications for most drugs in the US.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIndication>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
