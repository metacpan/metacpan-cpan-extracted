package SoggyOnion::Plugin::GeoWeather;
use warnings;
use strict;
use base qw( SoggyOnion::Plugin );

our $VERSION = '0.04';

use Geo::Weather;

sub content {
    my $self = shift;

    # we need either the city&state or a zip code
    my @args;
    if ( exists $self->{zip} ) {
        @args = ( $self->{zip} );
    }
    elsif ( exists $self->{city} && exists $self->{state} ) {
        @args = ( $self->{city}, $self->{state} );
    }
    else {
        warn __PACKAGE__ . " hash must have 'zip' or 'city' and 'state'\n";
        return;
    }

    # get the weather
    my $weather = Geo::Weather->new;
    $weather->get_weather(@args);
    return $weather->report . "<hr/>" . $weather->report_forecast;
}

1;

__END__

=head1 NAME

SoggyOnion::Plugin::GeoWeather - get the weather

=head1 SYNOPSIS

In F<config.yaml>:

    layout:
      - title: Weather
        name:  weather.html
        items:
        
          - plugin: SoggyOnion::Plugin::GeoWeather
            id: weatherdotcom
            zip: '02115'

 ..or..

          - plugin: SoggyOnion::Plugin::GeoWeather
            id: weatherdotcom
            city: Boston
            state: MA

=head1 DESCRIPTION

This is a plugin for L<SoggyOnion> that gets the weather.

=head2 Item Options

=over 4

=item * C<id> - the item ID that appears in the HTML C<E<lt>DIVE<gt>> tag

=item * C<zip>

=item * C<city> and C<state>

=back

=head1 SEE ALSO

L<SoggyOnion>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
