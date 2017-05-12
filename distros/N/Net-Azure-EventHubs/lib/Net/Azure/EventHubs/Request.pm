package Net::Azure::EventHubs::Request;
use strict;
use warnings;

use parent 'HTTP::Request';
use Net::Azure::EventHubs::Response;
use Carp;

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw[agent]],
);

sub do {
    my $self = shift;
    my $res = $self->agent->request($self);
    croak $res->status_line if !$res->is_success;
    bless $res, 'Net::Azure::EventHubs::Response';
}

1;

=encoding utf-8

=head1 NAME

Net::Azure::EventHubs::Request - A Request Class for Net::Azure::EventHubs 

=head1 SYNOPSIS

    use Net::Azure::EventHubs::Request;
    use LWP::UserAgent;
    my $req = Net::Azure::EventHubs::Request->new(GET => 'http://...');
    $req->agent(LWP::UserAgent->new);
    my $res = $req->do;

=head1 DESCRIPTION

Net::Azure::EventHubs::Request is a request class for Net::Azure::EventHubs.

It inherits HTTP::Request.

=head1 METHODS

=head2 new

A constructor method. 

=head2 agent 

    my $agent = LWP::UserAgent->new(...);
    $req->agent($agent);

An accessor for setting/getting a LWP::UserAgent object

=head2 do

    my $res = $req->do;

Do itself as http/https request with agent. Then returns a response object.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

