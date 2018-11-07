use utf8;

package SemanticWeb::Schema::TVSeason;

# ABSTRACT: Season dedicated to TV broadcast and associated online delivery.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWorkSeason SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'TVSeason';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has country_of_origin => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'countryOfOrigin',
);



has part_of_tv_series => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfTVSeries',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TVSeason - Season dedicated to TV broadcast and associated online delivery.

=head1 VERSION

version v0.0.4

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

=head2 C<part_of_tv_series>

C<partOfTVSeries>

The TV series to which this episode or season belongs.

A part_of_tv_series should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TVSeries']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
