package Splunk::HEC::Response;
use Carp;
use Splunk::Base -base;
use strict;

has success => 1;
has status  => 200;
has reason  => '';
has content => '';

sub is_error {
  my $self = shift;
  return !$self->success;
}

sub is_success {
  my $self = shift;
  return $self->success;
}

sub TO_JSON {
  my $self = shift;
  my %res = map { $_ => $self->{$_} } keys %$self;
  return \%res;
}

1;

=encoding utf8

=head1 NAME

Splunk::HEC::Response - An object wrapper for HEC responses

=head1 SYNOPSIS

  use Splunk::HEC;

  my $hec = Splunk::HEC->new;
  my $res = $hec->send(event => 'testEvent');
  if ($res->is_success)  { say $res->content }
  elsif ($res->is_error) { say $res->reason }

=head1 DESCRIPTION

L<Splunk::HEC::Response> is an object wrapper for HEC responses

=head1 ATTRIBUTES

L<Splunk::HEC::Response> implements the following attributes.

=head2 success

  my $sucess = $res->success;
  $success = $res->success(0);

Indicates if the HEC request was successful.

=head2 status

  my $status = $res->status;
  $status = $res->status(200);

HTTP Status Code from HEC request.

=head2 reason

  my $reason = $res->reason;
  $reason = $res->reason('An error occurred.');

String error message if the response was an error.

=head2 content

  my $content = $res->content;
  $content = $res->content({text => 'Success', code => 0});

The contents of a successful HEC request (decoded from JSON)

=head2 is_error

  my $is_error = $res->is_error;

Returns true if the response was an error.

=head2 is_success

  my $is_success = $res->is_success;

Returns true if the request was a success.

=head1 METHODS

L<Splunk::HEC::Response> implements the following methods.

=head2 new

  my $res = Splunk::HEC::Response->new;
  my $res = Splunk::HEC::Response->new(success => 0, reason => 'Generic Error');
  my $res = Splunk::HEC::Response->new({success => 0, reason => 'Generic Error'});

This is the constructor used to create the Splunk::HEC::Response object. You can
pass it either a hash or a hash reference with attribute values.

=head2 TO_JSON

  my $hash = $res->TO_JSON;

Returns a JSON encoding friendly hashref for use with L<JSON::XS>

=head1 SEE ALSO

L<Splunk::HEC::Request>, L<Splunk::HEC::Response>, L<Splunk::HEC>, L<HTTP::Tiny>, L<JSON::XS>

=cut
