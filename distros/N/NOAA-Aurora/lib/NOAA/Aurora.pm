package NOAA::Aurora;

use 5.006;
use strict;
use warnings;

use parent 'Weather::API::Base';
use Weather::API::Base qw(:all);

=head1 NAME

NOAA::Aurora - Simple client for NOAA's Aurora Forecast Service

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

  use NOAA::Aurora;

  # Constructor can use RFC 3339 or ISO instead of timestamps for timeseries
  my $aurora = NOAA::Aurora->new(date_format => 'rfc');

  # Save the latest probability map to an image file
  $aurora->get_image(hemisphere => 'north', output => 'aurora_north.jpg');

  # Get aurora probability for a given location
  my $probability = $aurora->get_probability(lat => 51.2, lon => -1.8);

  # Get 3-day forecast as a timeseries
  my $forecast = $aurora->get_forecast();

  # Get 27-day outlook as a timeseries
  my $outlook = $aurora->get_outlook();

=head1 DESCRIPTION

NOAA::Aurora provides basic access to the L<NOAA Space Weather Prediction Center (SWPC)|https://www.swpc.noaa.gov/>
Aurora Forecast API. This service provides real-time aurora forecasts based on solar activity and geomagnetic conditions.

The module fetches aurora probability data, latest aurora images, and the 3-day aurora forecast.

Responses are cached (by default for 120 sec).

=head1 CONSTRUCTOR

=head2 C<new>

    my $aurora = NOAA::Aurora->new(
        cache       => $cache_secs?,
        swpc        => $swpc_services_subdomain,
        date_format => $unix_rfc_or_iso,
        timeout     => $timeout_sec?,
        agent       => $user_agent_string?,
        ua          => $lwp_ua?,
    );
  
Optional parameters:

=over 4

=item * C<cache> : Will cache results for the specified seconds. Default: C<120>.

=item * C<swpc> : Space Weather Prediction Center subdomain. Default: C<services.swpc.noaa.gov>.

=item * C<date_format> : Format for functions that return dates/timestamps.
Can be C<unix> (unix timestamp), C<rfc> (for I<YYYY-MM-DD HH:mm:ssZ>) or C<iso> (for I<YYYY-MM-DDTHH:mm:ssZ>).
Default: C<unix>.

=item * C<timeout> : Timeout for requests in secs. Default: C<30>.

=item * C<agent> : Customize the user agent string.

=item * C<ua> : Pass your own L<LWP::UserAgent> to customise further.

=back

Note that the module base is L<Weather::API::Base>, so some additional parameters
are inherited - see the base module for details.

=head1 METHODS

=head2 C<get_image>

    my $image_data = $aurora->get_image(
        hemisphere => $hem,
        output     => $filename?
    );

Returns the latest aurora oval image for the specified hemisphere in jpg data.
Optionally will save it to $filename.
Function caches the results (see constructor).

Optional parameters:

=over 4

=item * C<hemisphere> : C<north> or C<south> (accepts abbreviations). Default: C<north>.

=item * C<output> : If specified will save to specified jpg file.

=back

=head2 C<get_probability>

    my $probability = $aurora->get_probability(
        lat  => $lat,
        lon  => $lon,
        hash => $return_hash?
    );

Fetches the aurora probability at a specific latitude and longitude if specified,
otherwise will return all the globe. Can return the original NOAA JSON string, or
decode it into a Perl hash of hashes:

    {
        $longitude1 => {$latitude1 => $prob},
        ...
    }

Probability given as an integer percentage value (0-100). Granularity is 1 degree.
In Perl hash mode, 0 probability locations will be ommitted from the response.

The function caches the results (see constructor), so subsequent calls will not
require downloading and decoding.

Optional parameters:

=over 4

=item * C<hash> : If true, will return Perl hash instead of JSON.

=back

=head2 C<get_forecast>

    my $forecast = $aurora->get_forecast(
        format => $output?
    );

Retrieves NOAA's 3-day space forecast (preferred over the geomagnetic forecast due
to more frequent / twice daily update) and by default returns an arrayref of hashes:

    [{time => $timestamp, kp => $kp_value},...]

The timestamp will be at the start of the 3h time range NOAA returns.

Optional parameters:

=over 4

=item * C<format> : If C<'text'> is specified as the format, raw text output will be returned
instead of an array with the timeseries.

=back

=head2 C<get_outlook>

    my $outlook = $aurora->get_outlook(
        format => $output?
    );

Retrieves NOAA's 27-day outlook with the forecasted daily values for the 10.7cm Solar
radio flux, the Planetary A Index and the largest Kp index. By default returns an
arrayref of hashes:

 [
   {
     time => $timestamp,
     flux => $flux_value,
     ap   => $a_index,
     kp   => $max_kp_value
   }, ...
 ]

=over 4

=item * C<format> : If C<'text'> is specified as the format, raw text output will be returned
instead of an array with the timeseries.

=back

=head1 UTILITY FUNCTIONS

=head2 C<kp_to_g>

    my $g_index = kp_to_g($kp_index);

Pass the Kp index and get the G-Index (Geomagnetic storm from G1 to G5) or 0 if
the Kp is not indicative of a Geomagnetic Storm. Fractional kp is rounded half up
(e.g. kp >= 4.5 -> G1).

=cut

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{data}  = {};
    $self->{cache} = $args{cache} // 120;
    $self->{swpc}  = $args{swpc}  || 'services.swpc.noaa.gov';
    $self->{swpc} =~ s#^http(?:s)?://##;
    # Time delimiter for rfc/iso
    my $time_f  = lc($args{date_format} || '');
    $self->{td} = ' ' if $time_f eq 'rfc';
    $self->{td} = 'T' if $time_f eq 'iso';

    return $self;
}

sub get_image {
    my $self = shift;
    my %args = @_;
    $args{hem} ||= $args{hemisphere} || '';

    my $h    = $args{hem} =~ /^s/i ? 'south' : 'north';
    my $data = $self->_get_cache($h) || $self->_set_cache(
        $h,
        $self->_get_output(
            $self->_get_ua(
                "$self->{swpc}/images/animations/ovation/$h/latest.jpg"
            )
        )
    );

    if ($args{output}) {
          open(my $fh, '>:raw', $args{output}) or die $!;
          print $fh $data;
          close($fh);
    }

    return $data;
}

sub get_probability {
    my $self = shift;
    my %args = @_;

    my ($json, $hash) = $self->_get_probabilities;

    if (defined $args{lat} && defined $args{lon}) {
        $args{$_} = sprintf("%.0f", $args{$_}) for qw/lat lon/;
        Weather::API::Base::_verify_lat_lon(\%args);
        return $hash->{$args{lon}}->{$args{lat}} || 0;
    }

    return $args{hash} ? $hash : $json;
}

sub _get_text_source {
    my $self    = shift;
    my $source  = shift;
    my %args    = @_;
    my $url     = "$self->{swpc}/text/$source.txt";
    my $resp    = $self->_get_ua($url);
    my $content = $resp->decoded_content;

    return $content if $args{format} && $args{format} eq 'text';

    return $source eq '3-day-forecast'
        ? $self->_parse_geo($content)
        : $self->_parse_outlook($content);
}

sub get_forecast {
    my $self = shift;
    return $self->_get_text_source('3-day-forecast', @_);
}

sub get_outlook {
    my $self = shift;
    return $self->_get_text_source('27-day-outlook', @_);
}

sub kp_to_g {
    my $kp = shift;
    return 0 if !$kp || $kp < 4.5;
    return 'G1' if $kp < 5.5;
    return 'G2' if $kp < 6.5;
    return 'G3' if $kp < 7.5;
    return 'G4' if $kp < 9;
    return 'G5';
}

sub _get_probabilities {
    my $self = shift;
    my $json = $self->_get_cache('json');
    my $hash = $self->_get_cache('hash');
    return ($json, $hash) if $json && $hash;
    return $self->_refresh_probability;
}

sub _refresh_probability {
    my $self = shift;
    my $resp = $self->_get_ua("$self->{swpc}/json/ovation_aurora_latest.json");
    my $json = $resp->decoded_content;
    my %raw  = $self->_get_output($resp, 1);
    $self->_set_cache('json', $json);
    my %hash;
    foreach (@{$raw{coordinates}}) {
        $hash{$_->[0]}->{$_->[1]} = $_->[2] if $_->[2];
    }
    $self->_set_cache('hash', \%hash);
    return ($json, \%hash);
}

sub _get_cache {
    my $self = shift;
    my $key  = shift;

    return
           unless $self->{cache} && $self->{data}->{$key}
        && (time() - $self->{data}->{$key}->{ts} <= $self->{cache});

    return $self->{data}->{$key}->{data};
}

sub _set_cache {
    my $self = shift;
    my $key  = shift;
    my $data = shift;

    $self->{data}->{$key}->{ts} = time();
    $self->{data}->{$key}->{data} = $data;

    return $data;
}

# Parse from last day to first, passing ref_month being the last month processed
sub _parse_mon_day {
    my ($date, $ref_year, $ref_mon) = @_;
    my ($mon, $day) = split /\s+/, $date;
    $mon = mon_to_num($mon);

    $ref_year-- if $ref_mon && $mon > $ref_mon;
    $date = sprintf("%d-%02d-%02d", $ref_year, $mon, $day);

    return wantarray ? ($date, $mon) : $date;
}

sub _parse_geo {
    my ($self, $data) = @_;
    my @lines = split /\n/, $data;
    my $g     = qr/(?:\(G\d\)\s+)?/;
    
    # Find year in the "NOAA Kp index breakdown" or "breakdown" line
    my $year;
    while (defined(my $line = shift @lines)) {
         if ($line =~ /Kp index breakdown\s+.*(\d{4})/i) {
             $year = $1;
             last;
         }
    }

    return [] unless $year;

    # Date headers
    my @dates;
    while (defined(my $line = shift @lines)) {
        if ($line =~ /^\s*([A-Za-z]{3}\s+\d+)\s+([A-Za-z]{3}\s+\d+)\s+([A-Za-z]{3}\s+\d+)/) {
            my ($dt3, $ref_mon) = _parse_mon_day($3, $year);
            @dates = map {scalar _parse_mon_day($_, $year, $ref_mon)} ($1, $2);
            push @dates, $dt3;
            last;
        }
    }

    return [] unless @dates;

    my %kp_data;
    my $td = $self->{td} || ' ';
    foreach my $line (@lines) {
        if ($line =~ /^\s*(\d{2})-\d{2}UT\s+([\d.]+)\s+$g([\d.]+)\s+$g([\d.]+)/) {
            my ($t, @kp) = ($1, $2, $3, $4);
            my @times = map {"$_$td$t:00:00Z"} @dates;
            @times = map {datetime_to_ts($_)} @times unless $self->{td};
            $kp_data{$times[$_]} = $kp[$_] for 0..2;
        }
    }

    my @result = map {{time => $_, kp => $kp_data{$_}}} sort keys %kp_data;
    return \@result;
}

sub _parse_outlook {
    my ($self, $data) = @_;
    my @lines = split /\n/, $data;
    my @result;

    my $td = $self->{td} || ' ';
    foreach my $line (@lines) {
        if ($line =~ /^\s*(\d{4})\s+([A-Z][a-z]{2})\s+(\d{2})\s+(\d+)\s+(\d+)\s+(\d+)/) {
            my ($year, $mon_str, $day, $flux, $ap, $kp) = ($1, $2, $3, $4, $5, $6);
            my $mnum = mon_to_num($mon_str);
            
            my $dt = sprintf("$year-%02d-%02d${td}00:00:00Z", $mnum, $day);
            my $ts = $self->{td} ? $dt : datetime_to_ts($dt);
            
            push @result, {
                time => $ts,
                flux => $flux,
                ap   => $ap,
                kp   => $kp,
            };
        }
    }
    return \@result;
}

=head1 AUTHOR

Dimitrios Kechagias, C<< <dkechag at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests either on L<GitHub|https://github.com/dkechag/NOAA-Aurora> (preferred), or on RT (via the email
C<bug-noaa-aurora at rt.cpan.org> or L<web interface|https://rt.cpan.org/NoAuth/ReportBug.html?Queue=NOAA-Aurora>).

=head1 GIT

L<https://github.com/dkechag/NOAA-Aurora>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Dimitrios Kechagias.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
