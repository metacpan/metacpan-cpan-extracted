package Test::Shodo::JSONRPC;
use strict;
use warnings;
use Shodo;
use parent qw/Exporter/;
use JSON qw/from_json/;
use Try::Tiny;
use Test::More;

our @EXPORT = qw/
    shodo_document_root
    shodo_test
    shodo_params
    shodo_req_ok
    shodo_res_ok
    shodo_doc
    shodo_write
/;

my $shodo = Shodo->new();
my $suzuri;

sub shodo_document_root {
    my $dir = shift;
    $shodo->document_root($dir);
}

sub shodo_test {
    my ($description, $coderef) = @_;
    $suzuri = $shodo->new_suzuri($description) unless $suzuri;
    my $result = Test::More::subtest($description => $coderef);
}

sub shodo_params {
    my %args = @_;
    $suzuri->params(%args);
}

sub shodo_req_ok {
    my ($req, $note) = @_;
    $suzuri->request($req);
    my $data = try {
        from_json($req->content);
    }catch{
        warn "$_\n";
    };
    return unless $data;
    return unless $suzuri->validate($data->{params});
    Test::More::ok($req, $note);
}

sub shodo_res_ok {
    my ($res, $code, $note) = @_;
    $suzuri->response($res);
    my $result = Test::More::is $res->code, 200, $note;
    $shodo->stock($suzuri->doc());
    $suzuri = undef;
    return $result;
}

sub shodo_doc {
    return $shodo->stock();
}

sub shodo_write {
    my $filename = shift;
    $shodo->write($filename);
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Shodo::JSONRPC - Test module using Shodo for JSON-RPC Web API

=head1 SYNOPSIS

    use Test::More;
    use Plack::Test;
    use HTTP::Request;
    use JSON qw/to_json/;
    use Test::Shodo::JSONRPC;

    # PSGI application
    my $app = sub {
        my $data = {
            jsonrpc => '2.0',
            result  => {
                entries =>
                  [ { title => 'Hello', body => 'This is an example.' } ]
            },
            id => 1
        };
        my $json = to_json($data);
        return [ 200, [ 'Content-Type' => 'application/json' ], [$json] ];
    };

    # use Plack::Test
    my $plack_test = Plack::Test->create($app);
    shodo_document_root('sample_documents');

    # shodo_test, like a subtest!
    shodo_test 'get_entries' => sub {
        shodo_params(
            category => { isa => 'Str', documentation => 'Category of articles.' },
            limit => { isa => 'Int', default => 20, optional => 1, documentation => 'Limitation numbers per page.' }
        );
        my $data = {
            jsonrpc => '2.0',
            method  => 'get_entries',
            params  => { limit => 1, category => 'technology' }
        };
        my $json = to_json($data);
        my $req  = HTTP::Request->new(
            'POST', '/',
            [
                'Content-Type'   => 'application/json',
                'Content-Length' => length $json
            ],
            $json
        );
        shodo_req_ok( $req, 'Request is valid!' );
        my $res = $plack_test->request($req);
        shodo_res_ok( $res, 200, 'Response is ok!' ); # auto sock document
    };

    shodo_write('some_methods.md'); # Generate a markdown-formatted document.

    done_testing();

=head1 DESCRIPTION

Shodo-based test module for JSON-RPC Web API.

=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Wada E<lt>yusuke@kamawada.comE<gt>

=cut
