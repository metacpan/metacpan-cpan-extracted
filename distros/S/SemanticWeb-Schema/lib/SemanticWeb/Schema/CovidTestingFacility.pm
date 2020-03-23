use utf8;

package SemanticWeb::Schema::CovidTestingFacility;

# ABSTRACT: A CovidTestingFacility is a MedicalClinic where testing for the COVID-19 Coronavirus disease is available

use Moo;

extends qw/ SemanticWeb::Schema::MedicalClinic /;


use MooX::JSON_LD 'CovidTestingFacility';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CovidTestingFacility - A CovidTestingFacility is a MedicalClinic where testing for the COVID-19 Coronavirus disease is available

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

=for html <p>A CovidTestingFacility is a <a class="localLink"
href="http://schema.org/MedicalClinic">MedicalClinic</a> where testing for
the COVID-19 Coronavirus disease is available. If the facility is being
made available from an established <a class="localLink"
href="http://schema.org/Pharmacy">Pharmacy</a>, <a class="localLink"
href="http://schema.org/Hotel">Hotel</a>, or other non-medical
organization, multiple types can be listed. This makes it easier to re-use
existing schema.org information about that place e.g. contact info,
address, opening hours. Note that in an emergency, such information may not
always be reliable.<p>

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalClinic>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
