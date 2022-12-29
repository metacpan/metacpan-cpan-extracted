package Power::Outlet::Common::IP::HTTP::JSON;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP};
#use Data::Dumper qw{Dumper};
use JSON qw{encode_json decode_json};

our $VERSION = '0.47';

=head1 NAME

Power::Outlet::Common::IP::HTTP::JSON - Power::Outlet base class for JSON power outlets

=head1 SYNOPSIS

  use base qw{Power::Outlet::Common::IP::HTTP::JSON};

=head1 DESCRIPTION

Power::Outlet::Common::IP::HTTP::JSON is a package for controlling and querying an JSON-based network attached power outlet.

=head1 USAGE

  use base qw{Power::Outlet::Common::IP::HTTP::JSON};

=head1 PROPERTIES

=head1 METHODS

=head2 json_request

JSON HTTP request response call

  my $response_data_structure=$outlet->json_request($method, $url, $request_data_structure);

Example:

  my $response_data_structure=$outlet->json_request(PUT=>"http://localhost/service", {foo=>"bar"});

=cut

sub json_request {
  my $self     = shift;
  my $method   = shift or die;
  my $url      = shift or die;
  my $input    = shift;
  my %options  = ();
  $options{"content"} = encode_json($input) if defined $input;
  #print "$method $url\n";
  #print Dumper(\%options);
  my $response = $self->http_client->request($method, $url, \%options);  
  if ($response->{"status"} eq "599") {
    die(sprintf(qq{HTTP Error: "%s %s", URL: "$url", Content: %s}, $response->{"status"}, $response->{"reason"}, $response->{"content"}));
  } elsif ($response->{"status"} ne "200") {
    die(sprintf(qq{HTTP Error: "%s %s", URL: "$url"}, $response->{"status"}, $response->{"reason"}));
  } 
  my $json     = $response->{"content"};
  #print "Response: $json\n";
  return decode_json($json);
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

=head1 SEE ALSO

L<JSON>

=cut

1;
