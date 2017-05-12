package Net::GPSD::Report::http;
use strict;
use warnings;
use LWP::UserAgent;

our $VERSION="0.39";

=head1 NAME

Net::GPSD::Report::http - Provides a perl interface to report position data. 

=head1 SYNOPSIS

  use Net::GPSD::Report::http;
  my $obj=Net::GPSD::Report::http->new();
  my $return=$obj->send(\%data);

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

  my $obj=Net::GPSD::Report::http->new({url=>$url});

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my $self=shift();
  my $data=shift();
  $data->{'url'}||='http://maps.davisnetworks.com/tracking/position_report.cgi';
  foreach (keys %$data) {
    $self->{$_}=$data->{$_};
  }
}

=head2 url

  $obj->url("http://localhost/path/script.cgi");
  my $url=$obj->url;

=cut

sub url {
  my $self = shift();
  if (@_) { $self->{'url'} = shift() } #sets value
  return $self->{'url'};
}

=head2 send

  my $httpreturn=$obj->send({device=>$int,
                             lat=>$lat,
                             lon=>$lon,
                             dtg=>"yyyy-mm-dd 24:mm:ss.sss",
                             speed=>$meterspersecond,
                             heading=>$degrees});

=cut

sub send {
  my $self=shift();
  my $data=shift(); #{}
  my $ua=LWP::UserAgent->new();
  my $res = $ua->post($self->url, $data);
  return $res->is_success ? $res->content : undef();
}

=head1 LIMITATIONS

=head1 BUGS

Email the author and log on RT.

=head1 SUPPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

Michael R. Davis, qw/gpsd michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<LWP::UserAgent>

=cut

1;
