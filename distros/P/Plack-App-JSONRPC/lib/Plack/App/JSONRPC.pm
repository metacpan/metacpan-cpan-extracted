package Plack::App::JSONRPC;
use 5.008001;
use strict;
use warnings;
our $VERSION = "0.02";

use parent qw(Plack::Component);
use JSON::RPC::Spec;
use Plack::Request;
use Plack::Util::Accessor qw(rpc);

sub prepare_app {
    my ($self) = @_;
    my $rpc = JSON::RPC::Spec->new;
    while (my ($name, $callback) = each %{$self->{methods}}) {
        $rpc->register($name, $callback);
    }
    $self->rpc($rpc);
    return;
}

sub call {
    my ($self, $env) = @_;
    my $req  = Plack::Request->new($env);
    my $body = $self->rpc->parse($req->content);
    if (length $body) {
        return [200, ['Content-Type' => 'application/json'], [$body]];
    }
    return [204, [], []];
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::App::JSONRPC - (DEPRECATED) Yet another JSON-RPC 2.0 psgi application

=head1 SYNOPSIS

    # app.psgi
    use Plack::App::JSONRPC;
    use Plack::Builder;
    my $jsonrpc = Plack::App::JSONRPC->new(
        methods => {
            echo  => sub { $_[0] },
            empty => sub {''}
        }
    );
    my $app = sub { [204, [], []] };
    builder {
        mount '/jsonrpc', $jsonrpc->to_app;
        mount '/' => $app;
    };

    # run
    $ plackup app.psgi

    # POST http://localhost:5000/jsonrpc
    #     {"jsonrpc":"2.0","method":"echo","params":"Hello","id":1}
    # return content
    #     {"jsonrpc":"2.0","result":"Hello","id":1}

=head1 DESCRIPTION

Plack::App::JSONRPC is Yet another JSON-RPC 2.0 psgi application

=head1 LICENSE

Copyright (C) nqounet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

nqounet E<lt>mail@nqou.netE<gt>

=cut

