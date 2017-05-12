#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Perinci::Access::Perl;
use Test::Exception;
use Test::More 0.98;

my $pa;
my $pa_cached;

subtest "request" => sub {
    subtest "only pl scheme is accepted" => sub {
        test_request(req => [info => "foo:/"], status=>501);
        test_request(req => [info => "pm:/"] , status=>501);
        test_request(req => [info => "pl:/"] , status=>200);
        test_request(req => [info => "/"]    , status=>200);
    };
};

subtest "parse_url" => sub {
    dies_ok { $pa->parse_url("/Perinci/Examples/") } "schemeless dies";
    is_deeply($pa->parse_url("pl:/Perinci/Examples/"),
              {proto=>"pl", path=>"/Perinci/Examples/"});
};

DONE_TESTING:
done_testing();

sub test_request {
    my %args = @_;
    my $req = $args{req};
    my $test_name = ($args{name} // "") . " (req: $req->[0] $req->[1])";
    subtest $test_name => sub {
        if ($args{object_opts}) {
            $pa = Perinci::Access::Perl->new(%{$args{object_opts}});
        } else {
            unless ($pa_cached) {
                $pa_cached = Perinci::Access::Perl->new();
            }
            $pa = $pa_cached;
        }
        my $res = $pa->request(@$req);
        if ($args{status}) {
            is($res->[0], $args{status}, "status")
                or diag explain $res;
        }
        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}, "result")
                or diag explain $res;
        }
        if ($args{posttest}) {
            $args{posttest}($res);
        }
        done_testing();
    };
}
