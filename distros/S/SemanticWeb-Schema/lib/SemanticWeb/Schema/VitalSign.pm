use utf8;

package SemanticWeb::Schema::VitalSign;

# ABSTRACT: Vital signs are measures of various physiological functions in order to assess the most basic body functions.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalSign /;


use MooX::JSON_LD 'VitalSign';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::VitalSign - Vital signs are measures of various physiological functions in order to assess the most basic body functions.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Vital signs are measures of various physiological functions in order to
assess the most basic body functions.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalSign>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
