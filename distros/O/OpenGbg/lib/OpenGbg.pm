use 5.10.0;
use strict;
use warnings;

package OpenGbg;

# ABSTRACT: An interface to the Open Data API of Gothenburg
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1402';

use OpenGbg::Elk;

use Config::Any;
use File::HomeDir;
use HTTP::Tiny;
use Path::Tiny;
use Types::Standard qw/HashRef Str/;
use Types::Path::Tiny qw/AbsFile/;
use namespace::autoclean;

use OpenGbg::Service::AirQuality;
use OpenGbg::Service::Bridge;
use OpenGbg::Service::StyrOchStall;
use OpenGbg::Service::TrafficCamera;

has config_file => (
    is => 'ro',
    isa => AbsFile,
    lazy => 1,
    builder => 1,
    init_arg => undef,
);
has config => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    builder => 1,
    init_arg => undef,
);
has key => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    builder => 1,
);
has ua => (
    is => 'ro',
    builder => 1,
    handles => ['get'],
);
has base => (
    is => 'ro',
    isa => Str,
    default => 'http://data.goteborg.se/',
);

my @services = qw/
    air_quality
    bridge
    styr_och_stall
    traffic_camera
/;
foreach my $service (@services) {
    has $service => (
        is => 'ro',
        lazy => 1,
        builder => 1,
    );
}

sub _build_config_file {
    my $home = File::HomeDir->my_home;
    my $conf_file = path($home)->child('.opengbg.ini');
}
sub _build_config {
    my $self = shift;

    my $cfg = Config::Any->load_files({
        use_ext => 1,
        files => [ $self->config_file ],
    });
    my $entry = shift @{ $cfg };
    my($filename, $config) = %{ $entry };
    return $config;
}
sub _build_key {
    return shift->config->{'API'}{'key'};
}
sub _build_ua {
    return HTTP::Tiny->new(agent => 'OpenGbg-Browser');
}

sub _build_air_quality {
    return OpenGbg::Service::AirQuality->new(handler => shift);
}
sub _build_bridge {
    return OpenGbg::Service::Bridge->new(handler => shift);
}
sub _build_styr_och_stall {
    return OpenGbg::Service::StyrOchStall->new(handler => shift);
}
sub _build_traffic_camera {
    return OpenGbg::Service::TrafficCamera->new(handler => shift);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenGbg - An interface to the Open Data API of Gothenburg



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-OpenGbg"><img src="https://api.travis-ci.org/Csson/p5-OpenGbg.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/OpenGbg-0.1402"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/OpenGbg/0.1402" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=OpenGbg%200.1402"><img src="http://badgedepot.code301.com/badge/cpantesters/OpenGbg/0.1402" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-78.7%-orange.svg" alt="coverage 78.7%" />
</p>

=end html

=head1 VERSION

Version 0.1402, released 2016-08-12.

=head1 SYNOPSIS

    use OpenGbg;

    my $opengbg = OpenGbg->new(key => 'secret-api-key');

    $stations = $opengbg->styr_och_stall->get_bike_stations;

    print $stations->get_by_index(0)->to_text;

=head1 DESCRIPTION

OpenGbg is a way to connect to and use the open data published by the city of L<Gothenburg|https://en.wikipedia.org/wiki/Gothenburg>.

The open data homepage is located at L<http://data.goteborg.se/>. All official documentation is in Swedish, but the license agreement is published
in English L<here|https://gbgdata.wordpress.com/goopen/>.

To use the API you need to sign up for a free api key.

=head2 Authenticate

Once you have your api key you can use it to authenticate in two different ways:

1. You can give it in the constructor:

    my $opengbg = OpenGbg->new(key => 'secret-api-key');

2. You can save it in a file named C<.opengbg.ini> in your homedir:

    [API]
    key = secret-api-key

=head1 METHODS

=head2 new()

Takes an optional key-value pair, the key is C<key> and the value your api key, see L<authenticate|/"Authenticate">.

    my $gbg = OpenGbg->new(key => 'secret-api-key');

    # or, if the api key is set in C<.opengbg.ini>:

    my $gbg = OpenGbg->new;

=head1 SERVICES

The following services are currently implemented in this distribution:

L<$gbg-E<gt>air_quality|OpenGbg::Service::AirQuality> - Data on air quality

L<$gbg-E<gt>bridge|OpenGbg::Service::Bridge> - Data on the openness of Göta Älvbron

L<$gbg-E<gt>styr_och_stall|OpenGbg::Service::StyrOchStall> - Data on rent-a-bike stations

L<$gbg-E<gt>traffic_camera|OpenGbg::Service::TrafficCamera> - Data on traffic cameras, and their images

=head2 Naming

Most names related to the services are de-camelized, while others are lower-cased (no underscores). For example, the service 'GetBikeStations' is called like this:

    my $gbg = OpenGbg->new;
    my $stations = $gbg->styr_och_stall->get_bike_stations;

All calls to services are prefixed with 'get' even if the service isn't named that way. On the other hand, the 'service' suffix on some services are removed.

Date/time intervals are always called C<start> and C<end> (in the web services they are sometimes called 'start' and 'stop').

=head1 DISCLAIMER

This is not an official distribution.

=head1 SOURCE

L<https://github.com/Csson/p5-OpenGbg>

=head1 HOMEPAGE

L<https://metacpan.org/release/OpenGbg>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
