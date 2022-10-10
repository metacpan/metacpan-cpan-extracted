package Power::Outlet::Common::IP::HTTP::UPnP;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP};
use XML::LibXML::LazyBuilder qw{DOM E};
use Net::UPnP::HTTP;
use Net::UPnP::ActionResponse;

our $VERSION = '0.46';

=head1 NAME

Power::Outlet::Common::IP::HTTP::UPnP - Power::Outlet base class for UPnP power outlet

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP::HTTP::UPnP};

=head1 DESCRIPTION

Power::Outlet::Common::IP::HTTP::UPnP is a package for controlling and querying an UPnP-based network attached power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP::HTTP::UPnP};

=head1 PROPERTIES

=head2 upnp_service_type

=cut

sub upnp_service_type {
  my $self=shift;
  $self->{"upnp_service_type"}=shift if @_;
  $self->{"upnp_service_type"}=$self->_upnp_service_type_default unless defined $self->{"upnp_service_type"};
  return $self->{"upnp_service_type"};
}

sub _upnp_service_type_default {"urn:Belkin:service:basicevent:1"}; #WeMo default

=head1 METHODS

=head2 upnp_request

Returns a L<Net::UPnP::ActionResponse> object

  my $res=$obj->upnp_request($request_type, $event_name, $value);
  my $res=$obj->upnp_request("Get", "BinaryState");
  my $res=$obj->upnp_request("Set", "BinaryState", 0);
  my $res=$obj->upnp_request("Set", "BinaryState", 1);

=cut

sub upnp_request {
  my $self         = shift;
  my $request_type = shift or die;                      #e.g. Get|Set
  my $event_name   = shift or die;                      #e.g. BinaryState
  my $action_name  = "$request_type$event_name";        #e.g. SetBinaryState

  my $soap_action  = sprintf(qq{"%s#%s"}, $self->upnp_service_type, $action_name);

  my $xmlns={"xmlns:s"=>"http://schemas.xmlsoap.org/soap/envelope/", "s:encodingStyle"=>"http://schemas.xmlsoap.org/soap/encoding/"};

  my $soap_content_obj;

  if ($request_type eq "Set") {
    die("Error: Value required for Set request type") unless @_;
    my $value = shift;
    $soap_content_obj = DOM(
                          E("s:Envelope"=>$xmlns,
                            E("s:Body"=>{},
                              E("u:$action_name"=>{"xmlns:u" => $self->upnp_service_type},
                                E($event_name=>{}, $value)))));
  } elsif ($request_type eq "Get") {
    $soap_content_obj = DOM(
                          E("s:Envelope"=>$xmlns,
                            E("s:Body"=>{},
                              E("u:$action_name"=>{"xmlns:u" => $self->upnp_service_type}))));
  } else {
    die(qq{Error: Unknown request type "$request_type".  Expected either "Get" or "Set".});
  }

  my $soap_content = $soap_content_obj->toString;

  #  Please note there is currently no way to build a Net::UPnP::Service from scratch.
  #  Bug Reported: https://rt.cpan.org/Ticket/Display.html?id=91711

  my $post_res = Net::UPnP::HTTP->new->postsoap(
                                                $self->host,      #method from Power::Outlet::Common::IP
                                                $self->port,      #method from Power::Outlet::Common::IP
                                                $self->http_path, #method from Power::Outlet::Common::HTTP
                                                $soap_action,
                                                $soap_content,
                                               );

  die(sprintf("Error: HTTP Request failed. Status Code: %s", $post_res->getstatuscode)) unless $post_res->getstatuscode == 200;

  my $action_res = Net::UPnP::ActionResponse->new;
  $action_res->sethttpresponse($post_res);

  return $action_res;
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

Copyright (c) 2013 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

Portions of the UPnP Implementation Copyright (c) 2013 Eric Blue

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net:UPnP>, L<XML::LibXML::LazyBuilder>

=cut

1;
