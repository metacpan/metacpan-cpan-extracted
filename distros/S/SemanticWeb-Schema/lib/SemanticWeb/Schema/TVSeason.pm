use utf8;

package SemanticWeb::Schema::TVSeason;

# ABSTRACT: Season dedicated to TV broadcast and associated online delivery.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::CreativeWorkSeason /;


use MooX::JSON_LD 'TVSeason';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has country_of_origin => (
    is        => 'rw',
    predicate => '_has_country_of_origin',
    json_ld   => 'countryOfOrigin',
);



has part_of_tv_series => (
    is        => 'rw',
    predicate => '_has_part_of_tv_series',
    json_ld   => 'partOfTVSeries',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TVSeason - Season dedicated to TV broadcast and associated online delivery.

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

Season dedicated to TV broadcast and associated online delivery.

=head1 ATTRIBUTES

=head2 C<country_of_origin>

C<countryOfOrigin>

The country of the principal offices of the production company or
individual responsible for the movie or program.

A country_of_origin should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Country']>

=back

=head2 C<_has_country_of_origin>

A predicate for the L</country_of_origin> attribute.

=head2 C<part_of_tv_series>

C<partOfTVSeries>

The TV series to which this episode or season belongs.

A part_of_tv_series should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TVSeries']>

=back

=head2 C<_has_part_of_tv_series>

A predicate for the L</part_of_tv_series> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWorkSeason>

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
