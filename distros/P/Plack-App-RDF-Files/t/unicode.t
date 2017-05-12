use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::App::RDF::Files;

foreach my $form (0,'NFD','NFKC') {
    my $app = Plack::App::RDF::Files->new( base_dir => 't/data', normalize => $form );

    test_psgi $app, sub {
        my ($cb, $res) = @_;

        $res = $cb->(GET "/unicode");

        foreach my $type (qw(application/rdf+xml application/x-rdf+json)) {
            $res = $cb->(GET "/unicode", Accept => $type);
            if ($form eq 'NFKC') {
                like $res->content, qr/1:ö/m, $form;
                like $res->content, qr/2:ö/m, $form;
                like $res->content, qr/3:ö ö/m, $form;
            } elsif ($form eq 'NFD') {
                like $res->content, qr/1:o\x{cc}\x{88}/m, $form;
                like $res->content, qr/2:o\x{cc}\x{88}/m, $form;
                like $res->content, qr/3:o\x{cc}\x{88} o\x{cc}\x{88}/m, $form;
            } else {
                like $res->content, qr/1:ö/m, "ö";
                like $res->content, qr/2:o\x{cc}\x{88}/m, "o + combining diaeresis (UTF-8)";
                like $res->content, qr/3:\x{c3}\x{b6} o\x{cc}\x{88}/m, "ö (UTF-8)";
            }
        }
    };
};

done_testing;
