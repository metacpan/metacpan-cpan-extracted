# ABSTRACT: Interface to COLOURlovers.com's API

package Net::COLOURlovers;
{
  $Net::COLOURlovers::VERSION = '0.01';
}

use strict;
use warnings;

use List::Util qw( first );
use LWP::UserAgent;

use base qw(
  Net::COLOURlovers::Color
  Net::COLOURlovers::Lover
  Net::COLOURlovers::Palette
  Net::COLOURlovers::Pattern
  Net::COLOURlovers::Stat
);

sub new {
    my $ua = LWP::UserAgent->new(
        'agent' => "Net::COLOURlovers/$Net::COLOURlovers::VERSION" );
    my $args = { 'ua' => $ua };

    return bless $args, __PACKAGE__;
}

sub _build_parametres {
    my ( $args, $parametres_ref ) = @_;

    my %parametre;
    for my $parametre (@$parametres_ref) {
        if ( first { $_ eq $parametre } keys %$args ) {
            $parametre{$parametre} = $args->{$parametre};
        }
    }

    return \%parametre;
}

1;



=pod

=head1 NAME

Net::COLOURlovers - Interface to COLOURlovers.com's API

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Net::COLOURlovers;

    my $cl = Net::COLOURlovers->new;

    my $pattern = $cl->pattern_random;
    my @colors = $cl->colors_top( { 'numResults' => 5 } );

A sample page built using this API can be found at: L<http://bit.ly/qtIepU>.

=head3 METHOD FORMAT

Each method listed below has its input and output parametres specified in
sections titled I<Input> and I<Output>. These sections are followed by the
parametre type:

=over 4

=item * B<C<UNDEF>> - accepts no parametre

=item * B<C<SCALAR>> - accepts/returns a B<C<SCALAR>>

=item * B<C<HASHREF>> - accepts/returns a B<C<HASH>>

=item * B<C<ARRAYREF> of C<HASHREF>s> - accepts/returns an B<C<ARRAY>> reference
which has B<C<HASH>> references as its elements

=back

=head1 ATTRIBUTES

=head2 C<new>

Constructs and returns a L<Net::COLOURlovers> object.

=head1 METHODS

=head2 C<color>

I<Input>: B<C<SCALAR>>

=over 4

=item * C<'color_name'>

A 6-character hexadecimal value like C<6B4106>.

=back

I<Output>: B<C<HASHREF>>

=over 4

=item * C<id>

=item * C<title>

=item * C<userName>

=item * C<numViews>

=item * C<numVotes>

=item * C<numComments>

=item * C<numHearts>

=item * C<rank>

=item * C<dateCreated>

=item * C<hex>

=item * C<rgb>

=over 4

=item * C<red>

=item * C<green>

=item * C<blue>

=back

=item * C<hsv>

=over 4

=item * C<hue>

=item * C<saturation>

=item * C<value>

=back

=item * C<description>

=item * C<url>

=item * C<imageUrl>

=item * C<badgeUrl>

=item * C<apiUrl>

=back

=head2 C<colors>, C<colors_new> and C<colors_top>

I<Input>: B<C<HASHREF>> (optional)

=over 4

=item * C<lover>

=item * C<hueRange>

=item * C<briRange>

=item * C<keywords>

=item * C<keywordExact>

=item * C<orderCol>

=item * C<sortBy>

=item * C<numResults>

=item * C<resultOffset>

=back

I<Output>: B<C<ARRAYREF> of C<HASHREF>s>

Format same as that for L</color>.

=head2 C<color_random>

I<Input>: B<C<UNDEF>>

I<Output>: B<C<HASHREF>>

Format same as that for L</color>.

=head2 C<lover>

I<Input>: B<C<SCALAR>>

=over 4

=item * C<'lover_name'>

A valid COLOURlovers.com username.

=back

I<Output>: B<C<HASHREF>>

=over 4

=item * C<userName>

=item * C<dateRegistered>

=item * C<dateLastActive>

=item * C<rating>

=item * C<location>

=item * C<numColors>

=item * C<numPalettes>

=item * C<numCommentsMade>

=item * C<numCommentsOnProfile>

=item * C<comments>

=item * C<url>

=item * C<apiUrl>

=back

=head2 C<lovers>, C<lovers_new> and C<lovers_top>

I<Input>: B<C<HASHREF>> (optional)

=over 4

=item * C<orderCol>

=item * C<sortBy>

=item * C<numResults>

=item * C<resultOffset>

=back

I<Output>: B<C<ARRAYREF> of C<HASHREF>s>

Format same as that for L</lover>.

=head2 C<palette>

I<Input>: B<C<SCALAR>>

=over 4

=item * C<'palette_id'>

A valid palette ID like C<113451>.

=back

I<Output>: B<C<HASHREF>>

=over 4

=item * C<id>

=item * C<title>

=item * C<userName>

=item * C<numViews>

=item * C<numVotes>

=item * C<numComments>

=item * C<numHearts>

=item * C<rank>

=item * C<dateCreated>

=item * C<colors>

=item * C<description>

=item * C<url>

=item * C<imageUrl>

=item * C<badgeUrl>

=item * C<apiUrl>

=back

=head2 C<palettes>, C<palettes_new> and C<palettes_top>

I<Input>: B<C<HASHREF>> (optional)

=over 4

=item * C<lover>

=item * C<hueOption>

=item * C<hex>

=item * C<keywords>

=item * C<keywordExact>

=item * C<orderCol>

=item * C<sortBy>

=item * C<numResults>

=item * C<resultOffset>

=item * C<showPaletteWidths>

=back

I<Output>: B<C<ARRAYREF> of C<HASHREF>s>

Format same as that for L</palette>.

=head2 C<palette_random>

I<Input>: B<C<UNDEF>>

I<Output>: B<C<HASHREF>>

Format same as that for L</palette>.

=head2 C<pattern>

I<Input>: B<C<SCALAR>>

=over 4

=item * C<'pattern_id'>

A valid pattern ID like C<1451>.

=back

I<Output>: B<C<ARRAYREF> of C<HASHREF>s>

=over 4

=item * C<id>

=item * C<title>

=item * C<userName>

=item * C<numViews>

=item * C<numVotes>

=item * C<numComments>

=item * C<numHearts>

=item * C<rank>

=item * C<dateCreated>

=item * C<colors>

=item * C<description>

=item * C<url>

=item * C<imageUrl>

=item * C<badgeUrl>

=item * C<apiUrl>

=back

=head2 C<patterns>, C<patterns_new> and C<patterns_top>

I<Input>: B<C<HASHREF>> (optional)

=over 4

=item * C<lover>

=item * C<hueOption>

=item * C<hex>

=item * C<keywords>

=item * C<keywordExact>

=item * C<orderCol>

=item * C<sortBy>

=item * C<numResults>

=item * C<resultOffset>

=back

I<Output>: B<C<ARRAYREF> of C<HASHREF>s>

Format same as that for L</pattern>.

=head2 C<pattern_random>

I<Input>: B<C<UNDEF>>

I<Output>: B<C<HASHREF>>

Format same as that for L</pattern>.

=head2 C<stats_colors>

Returns total number of colors.

=head2 C<stats_lovers>

Returns total number of lovers.

=head2 C<stats_palettes>

Returns total number of palettes.

=head2 C<stats_patterns>

Returns total number of patterns.

=encoding utf8

=head1 SEE ALSO

L<COLOURLovers API Documentation|http://www.colourlovers.com/api>

=head1 ATTRIBUTION CREDIT

L<COLOURlovers.com|http://www.colourlovers.com/>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

