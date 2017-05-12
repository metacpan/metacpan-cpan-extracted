#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Access;
use Perinci::Examples;

ok 1;
done_testing;

sub test_request {
    my %args = @_;
    my $req = $args{req};
    my $test_name = ($args{name} // "") . " ($req->[0] $req->[1])";
    subtest $test_name => sub {
        state $pa_cached;
        my $pa;
        if ($args{object_opts}) {
            $pa = Perinci::Access->new(%{$args{object_opts}});
        } else {
            unless ($pa_cached) {
                $pa_cached = Perinci::Access->new;
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
