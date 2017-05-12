package    # private
  Net::COLOURlovers::Color;

use strict;
use warnings;

use JSON qw( from_json );

sub color {
    my ( $self, $color ) = @_;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/color/$color?format=json");
    return ( from_json $response->content )->[0];
}

sub colors {
    my ( $self, $args, $url ) = @_;

    $args = Net::COLOURlovers::_build_parametres(
        $args,
        [
            qw(
              lover hueRange briRange keywords keywordExact orderCol sortBy
              numResults resultOffset
              )
        ]
    );

    my $response =
      $self->{'ua'}
      ->post( $url || 'http://www.colourlovers.com/api/colors?format=json',
        $args );

    return from_json $response->content;
}

sub colors_new {
    my ( $self, $args ) = @_;
    return $self->colors( $args,
        'http://www.colourlovers.com/api/colors/new?format=json' );
}

sub colors_top {
    my ( $self, $args ) = @_;
    return $self->colors( $args,
        'http://www.colourlovers.com/api/colors/top?format=json' );
}

sub color_random {
    my ( $self, $args ) = @_;
    return (
        $self->colors(
            {}, 'http://www.colourlovers.com/api/colors/random?format=json'
        )
    )->[0];
}

1;

__END__
=pod

=head1 NAME

Net::COLOURlovers::Color

=head1 VERSION

version 0.01

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

