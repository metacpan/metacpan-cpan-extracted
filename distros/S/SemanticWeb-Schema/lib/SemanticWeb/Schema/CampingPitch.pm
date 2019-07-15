use utf8;

package SemanticWeb::Schema::CampingPitch;

# ABSTRACT: A <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'CampingPitch';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CampingPitch - A <a class="localLink" href="http://schema

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

=for html A <a class="localLink"
href="http://schema.org/CampingPitch">CampingPitch</a> is an individual
place for overnight stay in the outdoors, typically being part of a larger
camping site, or <a class="localLink"
href="http://schema.org/Campground">Campground</a>.<br/><br/> In British
English a campsite, or campground, is an area, usually divided into a
number of pitches, where people can camp overnight using tents or camper
vans or caravans; this British English use of the word is synonymous with
the American English expression campground. In American English the term
campsite generally means an area where an individual, family, group, or
military unit can pitch a tent or park a camper; a campground may contain
many campsites. (Source: Wikipedia see <a
href="https://en.wikipedia.org/wiki/Campsite">https://en.wikipedia.org/wiki
/Campsite</a>).<br/><br/> See also the dedicated <a
href="/docs/hotels.html">document on the use of schema.org for marking up
hotels and other forms of accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

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
