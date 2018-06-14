package Net::Azure::NotificationHubs::Response;
use strict;
use warnings;

use JSON;
use Carp;
use Class::Accessor::Lite (
    ro => [qw[status reason headers content success]],
    new => 0
);

sub new {
    my ($class, $status, $reason, $headers, $content, $success) = @_;
    bless {
        status => $status,
        reason => $reason,
        headers => $headers || {},
        content => $content,
        success => $success,
    }, $class;
}

sub as_hashref {
    my $self = shift;
    return if !$self->success;
 
    my $type = $self->headers->{'content-type'};

    if ($type && $type =~ /\Aapplication\/json/) {
        return JSON->new->utf8(1)->decode($self->{content});
    }
    return;
}
 
1;

=encoding utf-8

=head1 NAME

Net::Azure::NotificationHubs::Response - A Response Class for Net::Azure::NotificationHubs 

=head1 SYNOPSIS

    use Net::Azure::NotificationHubs::Request;
    use HTTP::Tiny;
    my $req = Net::Azure::NotificationHubs::Request->new(GET => 'http://...');
    $req->agent(HTTP::Tiny->new);
    my $res = $req->do;
    my $json_data = $res->as_hashref;

=head1 DESCRIPTION

Net::Azure::NotificationHubs::Response is a response class for Net::Azure::NotificationHubs.

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
