#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Capture::Tiny qw(capture);
use Cwd;
use Perinci::Access::Simple::Client;
use Perinci::Access::Simple::Server::Pipe;

subtest "v1.1" => sub {
    my $pa  = Perinci::Access::Simple::Client->new;
    my $res = $pa->request(
        call => "riap+pipe:$^X"."//"."script%2Fperi-pipe"."//".
            "Perinci/Examples/sum",
        {args=>{array=>[1,2,3,4,5]}});

    is_deeply($res, [200, "OK", 15, {"riap.v"=>1.1}])
        or diag explain $res;
};

subtest "v1.2 (autoencoding of binary result)" => sub {
    my $srv = Perinci::Access::Simple::Server::Pipe->new;
    $srv->req({v=>1.2, action=>"call",
               uri=>"/Perinci/Examples/test_binary", args=>{}});
    $srv->handle;
    my ($stdout, undef, $exit) = capture { $srv->send_response() };
    my $exp_output = q(j[200,"OK","AAAA",{"riap.result_encoding":"base64","riap.v":1.2,"x.hint.result_binary":1}])."\015\012";
    is($stdout, $exp_output, 'output');
};

done_testing();
