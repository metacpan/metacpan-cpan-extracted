package Power::Outlet::Common::IP::HTTP;
use strict;
use warnings;
use URI qw{};
use HTTP::Tiny qw{};
use base qw{Power::Outlet::Common::IP};

our $VERSION='0.43';

=head1 NAME

Power::Outlet::Common::IP::HTTP - Power::Outlet base class for HTTP power outlet

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP::HTTP};

=head1 DESCRIPTION
 
Power::Outlet::Common::IP::HTTP is a package for controlling and querying an HTTP-based network attached power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP::HTTP};

=head1 METHODS

=head2 url

Returns a configured L<URI::http> object

=cut

sub url {
  my $self=shift;
  $self->{"url"}=shift if @_;
  unless (defined $self->{"url"}) {
    my $url=URI->new;
    $url->scheme("http");
    $url->host($self->host);      #from Power::Outlet::Common::IP
    $url->port($self->port);      #from Power::Outlet::Common::IP
    $url->path($self->http_path); #from Power::Outlet::Common::IP::HTTP
    $self->{"url"}=$url;
  }
  die unless $self->{"url"}->isa("URI");
  return $self->{"url"}->clone;
}

=head1 PROPERTIES

=cut

sub _port_default {"80"};            #HTTP

=head2 http_path

Set and returns the http_path property

Default: /

=cut

sub http_path {
  my $self=shift;
  $self->{"http_path"}=shift if @_;
  $self->{"http_path"}=$self->_http_path_default unless defined $self->{"http_path"};
  return $self->{"http_path"};
}

sub _http_path_default {"/upnp/control/basicevent1"}; #WeMo

=head1 OBJECT ACCESSORS

=head2 http_client

Returns a cached L<HTTP::Tiny> web client

=cut

sub http_client {
  my $self=shift;
  $self->{"http_client"}=shift if @_;
  $self->{"http_client"}=HTTP::Tiny->new
    unless ref($self->{"http_client"}) eq "HTTP::Tiny";
  return $self->{"http_client"};
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<URI>, L<HTTP::Tiny>

=cut

1;
