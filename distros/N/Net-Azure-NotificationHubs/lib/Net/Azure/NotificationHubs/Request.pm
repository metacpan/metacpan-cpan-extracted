package Net::Azure::NotificationHubs::Request;
use strict;
use warnings;
 
use Net::Azure::NotificationHubs::Response;
use Carp;
use URI;
 
use Class::Accessor::Lite (
    new => 0,
    rw  => [qw[agent]],
    ro  => [qw[method uri headers content]],
);

sub new {
    my ($class, $method, $uri, $headers, $content) = @_;
    bless {
        method  => $method, 
        uri     => ref($uri) =~ /\AURI::/ ? $uri : URI->new($uri),
        headers => $headers || {},
        content => $content,
    }, $class;
}

sub header {
    my ($self, $key, $value) = @_;
    return $self->{headers} if !$key;
    if (defined $value) {
        $self->{headers}{$key} = $value;
    }
    return $self->{headers}{$key};
}
 
sub do {
    my $self = shift;
    my $options = {headers => $self->headers};
    if ($self->content) {
        $options->{content} = $self->content;
    }

    my $res = $self->agent->request($self->method, $self->uri, $options);
    my $status = delete $res->{status};
    my $reason = delete $res->{reason};
    my $headers = delete $res->{headers};
    my $content = delete $res->{content};

    croak "$status $reason" if !$res->{success};

    Net::Azure::NotificationHubs::Response->new(
        $status, $reason, $headers, $content, $res->{success}
    );
}
 
1;

=encoding utf-8

=head1 NAME

Net::Azure::NotificationHubs::Request - A Request Class for Net::Azure::NotificationHubs 

=head1 SYNOPSIS

    use Net::Azure::NotificationHubs::Request;
    use HTTP::Tiny;
    my $req = Net::Azure::NotificationHubs::Request->new(GET => 'http://...');
    $req->agent(HTTP::Tiny->new);
    my $res = $req->do;

=head1 DESCRIPTION

Net::Azure::NotificationHubs::Request is a request class for Net::Azure::NotificationHubs.

=head1 METHODS

=head2 new

A constructor method. 

=head2 agent 

    my $agent = HTTP::Tiny->new(...);
    $req->agent($agent);

An accessor for setting/getting a HTTP::Tiny object

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
