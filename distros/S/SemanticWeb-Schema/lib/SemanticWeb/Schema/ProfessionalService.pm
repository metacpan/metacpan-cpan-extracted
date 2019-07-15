use utf8;

package SemanticWeb::Schema::ProfessionalService;

# ABSTRACT: Original definition: "provider of professional services

use Moo;

extends qw/ SemanticWeb::Schema::LocalBusiness /;


use MooX::JSON_LD 'ProfessionalService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ProfessionalService - Original definition: "provider of professional services

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html Original definition: "provider of professional services."<br/><br/> The
general <a class="localLink"
href="http://schema.org/ProfessionalService">ProfessionalService</a> type
for local businesses was deprecated due to confusion with <a
class="localLink" href="http://schema.org/Service">Service</a>. For
reference, the types that it included were: <a class="localLink"
href="http://schema.org/Dentist">Dentist</a>, <a class="localLink"
href="http://schema.org/AccountingService">AccountingService</a>, <a
class="localLink" href="http://schema.org/Attorney">Attorney</a>, <a
class="localLink" href="http://schema.org/Notary">Notary</a>, as well as
types for several kinds of <a class="localLink"
href="http://schema.org/HomeAndConstructionBusiness">HomeAndConstructionBus
iness</a>: <a class="localLink"
href="http://schema.org/Electrician">Electrician</a>, <a class="localLink"
href="http://schema.org/GeneralContractor">GeneralContractor</a>, <a
class="localLink" href="http://schema.org/HousePainter">HousePainter</a>,
<a class="localLink" href="http://schema.org/Locksmith">Locksmith</a>, <a
class="localLink" href="http://schema.org/Plumber">Plumber</a>, <a
class="localLink"
href="http://schema.org/RoofingContractor">RoofingContractor</a>. <a
class="localLink" href="http://schema.org/LegalService">LegalService</a>
was introduced as a more inclusive supertype of <a class="localLink"
href="http://schema.org/Attorney">Attorney</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::LocalBusiness>

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
