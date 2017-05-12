package Mojo::YR;

=head1 NAME

Mojo::YR - Get weather information from yr.no

=head1 DESCRIPTION

L<Mojo::YR> is an (a)synchronous weather data fetcher for the L<Mojolicious>
framework. The backend for weather data is L<http://yr.no>.

Look at the resources below for mere information about the API:

=over 4

=item * L<http://api.met.no/weatherapi/documentation>

=item * L<http://api.met.no/weatherapi/locationforecast/1.9/documentation>

=item * L<http://api.met.no/weatherapi/textforecast/1.6/documentation>

=item * L<http://api.met.no/weatherapi/sunrise/1.1/documentation>

=back

=head1 SYNOPSIS

  use Mojo::YR;
  my $yr = Mojo::YR->new;

  # Fetch location_forecast ==========================================
  my $now = $yr->location_forecast([59, 10])->find('pointData > time')->first;
  my $temp = $now->at('temperature');

  warn "$temp->{value} $temp->{unit}";

  # Fetch text_forecast ==============================================
  my $today = $yr->text_forecast->children('time')->first;
  my $hordaland = $today->at('area[name="Hordaland"]');

  warn $hordaland->at('header')->text;
  warn $hordaland->at('in')->text; # "in" holds the forecast text

=cut

use Mojo::Base -base;
use Mojo::UserAgent;

our $VERSION = '0.06';

=head1 ATTRIBUTES

=head2 url_map

  $hash_ref = $self->url_map;

Returns the URL used to fetch data.

Note: These will always be pointers to the current version. If you require a
specific version, set it manually. Note: YR have short deprecation cycles.

Default:

  {
    location_forecast => 'http://api.yr.no/weatherapi/locationforecast/1.9/',
    text_forecast => 'http://api.yr.no/weatherapi/textforecast/1.6/',
  };

=cut

has url_map => sub {
  my $self = shift;

  return {
    location_forecast => 'http://api.met.no/weatherapi/locationforecast/1.9/',
    text_forecast     => 'http://api.met.no/weatherapi/textforecast/1.6/',
    text_location_forecast => 'http://api.met.no/weatherapi/textlocation/1.0/',
    sunrise                => 'http://api.met.no/weatherapi/sunrise/1.1/',
  };
};

has _ua => sub {
  Mojo::UserAgent->new;
};

=head1 METHODS

=head2 location_forecast

  $self = $self->location_forecast([$latitude, $longitude], sub { my($self, $err, $dom) = @_; ... });
  $self = $self->location_forecast(\%args, sub { my($self, $err, $dom) = @_; ... });
  $dom = $self->location_forecast([$latitude, $longitude]);
  $dom = $self->location_forecast(\%args);

Used to fetch
L<weather forecast for a specified place|http://api.yr.no/weatherapi/locationforecast/1.9/documentation>.

C<%args> is required (unless C<[$latitude,$longitude]> is given):

  {
    latitude => $num,
    longitude => $num,
  }

C<$dom> is a L<Mojo::DOM> object you can use to query the result.
See L</SYNOPSIS> for example.

=cut

sub location_forecast {
  my ($self, $args, $cb) = @_;
  my $url = Mojo::URL->new($self->url_map->{location_forecast});

  if (ref $args eq 'ARRAY') {
    $args = {latitude => $args->[0], longitude => $args->[1]};
  }
  if (2 != grep { defined $args->{$_} } qw( latitude longitude )) {
    return $self->$cb('latitude and/or longitude is missing', undef);
  }

  $url->query([lon => $args->{longitude}, lat => $args->{latitude},]);

  $self->_run_request($url, $cb);
}

=head2 text_location_forecast

  $self = $self->text_location_forecast([$latitude, $longitude], sub { my($self, $err, $dom) = @_; ... });
  $self = $self->text_location_forecast(\%args, sub { my($self, $err, $dom) = @_; ... });
  $dom = $self->text_location_forecast([$latitude, $longitude]);
  $dom = $self->text_location_forecast(\%args);

Used to fetch
L<textual weather forecast for a specified place|http://api.yr.no/weatherapi/textlocation/1.0/documentation>.

C<%args> is required (unless C<[$latitude,$longitude]> is given):

  {
    latitude => $num,
    longitude => $num,
    language => 'nb', # default
  }

C<$dom> is a L<Mojo::DOM> object you can use to query the result.
See L</SYNOPSIS> for example.

=cut

sub text_location_forecast {
  my ($self, $args, $cb) = @_;
  my $url = Mojo::URL->new($self->url_map->{text_location_forecast});

  if (ref $args eq 'ARRAY') {
    $args = {latitude => $args->[0], longitude => $args->[1]};
  }
  if (2 != grep { defined $args->{$_} } qw( latitude longitude )) {
    return $self->$cb('latitude and/or longitude is missing', undef);
  }
  $args->{language} ||= 'nb';

  $url->query($args);

  $self->_run_request($url, $cb);
}


=head2 text_forecast

  $dom = $self->text_forecast(\%args);
  $self = $self->text_forecast(\%args, sub { my($self, $err, $dom) = @_; ... });

Used to fetch
L<textual weather forecast for all parts of the country|http://api.yr.no/weatherapi/textforecast/1.6/documentation>.

C<%args> is optional and has these default values:

  {
    forecast => 'land',
    language => 'nb',
  }

C<$dom> is a L<Mojo::DOM> object you can use to query the result.
See L</SYNOPSIS> for example.

=cut

sub text_forecast {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;
  my $args = shift || {};
  my $url  = Mojo::URL->new($self->url_map->{text_forecast});

  $url->query(
    [
      forecast => $args->{forecast} || 'land',
      language => $args->{language} || 'nb',
    ]
  );

  $self->_run_request($url, $cb);
}

=head2 sunrise

  $dom = $self->sunrise(\%args);
  $self = $self->sunrise(\%args, sub { my($self, $err, $dom) = @_; ... });

Used to fetch
L<When does the sun rise and set for a given place|http://api.yr.no/weatherapi/sunrise/1.0/documentation>

C<%args> is required

  {
    lat => $num,
    lon => $num,
    date => 'YYYY-MM-DD', # OR
    from => 'YYYY-MM-DD',
    to   => 'YYYY-MM-DD',
  }

C<$dom> is a L<Mojo::DOM> object you can use to query the result.
See L</SYNOPSIS> for example.

=cut

sub sunrise {
  my $cb   = ref $_[-1] eq 'CODE' ? pop : undef;
  my $self = shift;
  my $args = shift || {};
  my $url  = Mojo::URL->new($self->url_map->{sunrise});

  $url->query($args);

  $self->_run_request($url, $cb);
}

sub _run_request {
  my ($self, $url, $cb) = @_;

  if (!$cb) {
    my $tx = $self->_ua->get($url);
    die scalar $tx->error if $tx->error;
    return $tx->res->dom->children->first;
  }

  Scalar::Util::weaken($self);
  $self->_ua->get(
    $url,
    sub {
      my ($ua, $tx) = @_;
      my $err = $tx->error;

      return $self->$cb($err, undef) if $err;
      return $self->$cb('', $tx->res->dom->children->first)
        ;    # <weather> is the first element. don't want that
    },
  );

  return $self;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>
Marcus Ramberg - C<mramberg@cpan.org>

=cut

1;
