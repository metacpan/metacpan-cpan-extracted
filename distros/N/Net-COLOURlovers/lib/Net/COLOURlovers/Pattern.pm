package    # private
  Net::COLOURlovers::Pattern;

use strict;
use warnings;

use JSON qw( from_json );

sub pattern {
    my ( $self, $pattern ) = @_;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/pattern/$pattern?format=json");
    return ( from_json $response->content )->[0];
}

sub patterns {
    my ( $self, $args, $url ) = @_;

    $args = Net::COLOURlovers::_build_parametres(
        $args,
        [
            qw(
              lover hueOption hex keywords keywordExact orderCol sortBy
              numResults resultOffset
              )
        ]
    );

    my $response =
      $self->{'ua'}
      ->post( $url || 'http://www.colourlovers.com/api/patterns?format=json',
        $args );

    return from_json $response->content;
}

sub patterns_new {
    my ( $self, $args ) = @_;
    return $self->patterns( $args,
        'http://www.colourlovers.com/api/patterns/new?format=json' );
}

sub patterns_top {
    my ( $self, $args ) = @_;
    return $self->patterns( $args,
        'http://www.colourlovers.com/api/patterns/top?format=json' );
}

sub pattern_random {
    my ( $self, $args ) = @_;
    return (
        $self->patterns(
            {}, 'http://www.colourlovers.com/api/patterns/random?format=json'
        )
    )->[0];
}

1;

__END__
=pod

=head1 NAME

Net::COLOURlovers::Pattern

=head1 VERSION

version 0.01

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

