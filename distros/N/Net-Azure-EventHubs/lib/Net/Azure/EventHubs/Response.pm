package Net::Azure::EventHubs::Response;
use strict;
use warnings;

use parent 'HTTP::Response';
use JSON;
use Carp;

sub as_hashref {
    my $self = shift;
    return if !$self->is_success;

    my $type = $self->header('Content-Type'); 
    if ($type && $type =~ /\Aapplication\/json/) {
        return JSON->new->utf8(1)->decode($self->content);
    }
    return;
}

1;

=encoding utf-8

=head1 NAME

Net::Azure::EventHubs::Response - A Response Class for Net::Azure::EventHubs 

=head1 SYNOPSIS

    use Net::Azure::EventHubs::Request;
    use LWP::UserAgent;
    my $req = Net::Azure::EventHubs::Request->new(GET => 'http://...');
    $req->agent(LWP::UserAgent->new);
    my $res = $req->do;
    my $json_data = $res->as_hashref;

=head1 DESCRIPTION

Net::Azure::EventHubs::Response is a response class for Net::Azure::EventHubs.

It inherits HTTP::Response.

=head1 METHODS

=head2 as_hashref

    my $json_data = $res->as_hashref;

Return a content data as hashref when content type is 'application/json'. Otherwise, undef is returned.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

