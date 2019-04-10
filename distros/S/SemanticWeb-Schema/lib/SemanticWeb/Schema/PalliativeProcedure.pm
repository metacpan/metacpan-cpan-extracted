use utf8;

package SemanticWeb::Schema::PalliativeProcedure;

# ABSTRACT: A medical procedure intended primarily for palliative purposes

use Moo;

extends qw/ SemanticWeb::Schema::MedicalProcedure SemanticWeb::Schema::MedicalTherapy /;


use MooX::JSON_LD 'PalliativeProcedure';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PalliativeProcedure - A medical procedure intended primarily for palliative purposes

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A medical procedure intended primarily for palliative purposes, aimed at
relieving the symptoms of an underlying health condition.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalTherapy>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
