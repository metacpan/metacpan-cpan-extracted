package    # private
  Net::COLOURlovers::Stat;

use strict;
use warnings;

use JSON qw( from_json );

sub stats_colors {
    my $self = shift;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/stats/colors?format=json");

    return ( from_json $response->content )->{'total'};
}

sub stats_lovers {
    my $self = shift;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/stats/lovers?format=json");

    return ( from_json $response->content )->{'total'};
}

sub stats_palettes {
    my $self = shift;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/stats/palettes?format=json");

    return ( from_json $response->content )->{'total'};
}

sub stats_patterns {
    my $self = shift;

    my $response =
      $self->{'ua'}
      ->post("http://www.colourlovers.com/api/stats/patterns?format=json");

    return ( from_json $response->content )->{'total'};
}

1;

__END__
=pod

=head1 NAME

Net::COLOURlovers::Stat

=head1 VERSION

version 0.01

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

