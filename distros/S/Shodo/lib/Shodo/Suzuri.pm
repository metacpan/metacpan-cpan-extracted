package Shodo::Suzuri;
use strict;
use warnings;
use Carp qw//;
use Try::Tiny;
use JSON qw/from_json to_json/;
use Data::Validator;
use Clone qw/clone/;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        hanshi => $args{hanshi}
    }, $class;
    $self->stash->{description} = $args{description} || '';
    $self;
}

sub hanshi {
    shift->{hanshi};
}

sub stash {
    my $self = shift;
    $self->{stash} ||= {};
    return $self->{stash};
}

sub request {
    my ($self, $req) = @_;
    unless (try { $req->isa('HTTP::Request') }) {
        Carp::croak("Request is not HTTP::Request: $req");
    }
    $self->stash->{method} = $req->method;
    $self->stash->{path} = $req->uri->path;
    $self->stash->{query} = $req->uri->query;
    $self->stash->{request_body} = $req->decoded_content;
    if($req->content_type =~ m!^application/json!) {
        my $json_body = to_json(from_json($self->stash->{request_body}, { utf8 => 1 }), { pretty => 1 });
        $self->stash->{request_body} = $json_body;
    }
    return $req;
}

sub response {
    my ($self, $res) = @_;
    unless (try { $res->isa('HTTP::Response') }) {
        Carp::croak("Response is not HTTP::Response: $res");
    }
    $self->stash->{code} = $res->code;
    $self->stash->{status_line} = $res->status_line;
    $self->stash->{response_body} = $res->decoded_content;
    if($res->content_type =~ m!^application/json!) {
        my $json_body = to_json(from_json($self->stash->{response_body}, { utf8 => 1}), { pretty => 1 });
        $self->stash->{response_body} = $json_body;
    }
    return $res;
}

sub document {
    my $self = shift;
    return $self->hanshi->render( $self->stash );
}

sub params {
    my ($self, %args) = @_;
    $self->stash->{rule} = clone(\%args);
    my $validator = Data::Validator->new( %args )->with('NoThrow');
    $self->{validator} = $validator;
}

sub validate {
    my ($self, @args) = @_;
    Carp::croak "Rule is not set on Suzuri instance" unless $self->{validator};
    my $result;
    if( ref $args[0] && ref $args[0] eq 'HASH') {
        $result = $self->{validator}->validate($args[0]);
    }else{
        $result = $self->{validator}->validate(@args);
    }
    if($self->{validator}->has_errors()) {
        return;
    }
    return $result;
}

*req = \&request;
*res = \&response;
*doc = \&document;
*rule = \&params;

1;

__END__

=encoding utf-8

=head1 NAME

Shodo::Suzuri - Request and Reponse Parser for Shodo

=head1 Methods

=head2 request

    $suzuri->request($req);

Set HTTP::Request object.

=head2 response

    $suzuri->response($res);

Set HTTP::Response object.

=head2 params

    $suzuri->params(
        category => { isa => 'Str', documentation => 'Category of articles.' },
        limit => { isa => 'Int', default => 20, optional => 1, documentation => 'Limitation numbers per page.' },
        page => { isa => 'Int', default => 1, optional => 1, documentation => 'Page number you want to get.' }
    );

Parameters for validation and documentation. These rules are based on L<Data::Validator>'s interfaces.

=head2 validate

    $suzuri->validate($params);

Validate with the rules defined by "params" method. Parameter must be HASH ref.

=head2 doc

    $suzuri->doc();

Return the Markdown formatted document for Web API.

=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Wada E<lt>yusuke@kamawada.comE<gt>

=cut
