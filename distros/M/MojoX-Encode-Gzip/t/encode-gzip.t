#!perl

use strict;
use warnings;

use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use MojoX::Encode::Gzip;
use Mojo::Transaction::HTTP;
use Mojo::Message::Response;
use Mojo::Headers;

open my $fh, "<$Bin/public/gzippable.txt" || die "can't open: $!";

my $res_object = Mojo::Message::Response->new;
$res_object->code(200)
           ->body( do{ local $/ = <$fh> } )
           ->headers->content_type( 'text/plain' );

my $tx = Mojo::Transaction::HTTP->new(
    res => $res_object,
);

isa_ok $tx, 'Mojo::Transaction::HTTP';

my $res = $tx->res;

isa_ok $res, 'Mojo::Message::Response';

{
    my $test= "Pre-check";
    is     $tx->error, undef, "$test: no tx error";
    is     $res->code, 200, "$test: starting with a 200 code";
    is     $res->headers->content_type, "text/plain", "$test: Starting with text/plain";
    cmp_ok $res->body_size, '>', 500, "$test: body_length > 500";
}

{
    my $test = "attempt with client request";
    MojoX::Encode::Gzip->new->maybe_gzip($tx);

    is     $res->code, 200, "$test: response code is 200";
    isnt   $res->headers->header('Content-Encoding'), 'gzip', " $test: Content-Encoding isn't set to gzip";
    is     $res->headers->content_type, "text/plain", "$test: Starting with text/plain";
    cmp_ok $res->body_size, '>', 500, "$test: body_length > 500";
}
{
    my $test = "client requests gzip, all systems go";
    $tx->req->headers->header('Accept-Encoding','gzip');
    MojoX::Encode::Gzip->new->maybe_gzip($tx, 1);

    is     $tx->res->code, 200, "$test: response code is 200";
    is     $tx->res->headers->header('Content-Encoding'), 'gzip', "$test: Content-Encoding is set to gzip";
    is     $tx->res->headers->header('Vary'), 'Accept-Encoding', "$test: Vary is set to Accept-Encoding";
    unlike $tx->res->body, qr/gzipping/, "$test: plain text is no longer there";
    cmp_ok $tx->res->body_size, '<', 500, "$test: body shrank";

}

done_testing();
