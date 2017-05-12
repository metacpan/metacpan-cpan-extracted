#!perl -T

use 5.010;
use strict;
use warnings;

use Org::To::HTML qw(org_to_html);
use Test::Differences;
use Test::More 0.96;

sub test_to_html {
    my %args = @_;

    subtest $args{name} => sub {
        my $res;
        eval {
            $res = org_to_html(%{$args{args}});
        };
        my $eval_err = $@;

        if ($args{dies}) {
            ok($eval_err, "dies");
            return;
        } else {
            ok(!$eval_err, "doesnt die") or diag("died with msg $eval_err");
        }

        if ($args{status}) {
            is($res->[0], $args{status}, "status");
        }

        if ($args{result}) {
            my $html = $res->[2];
            $html =~ s/<!-- .* -->\n//sg;
            eq_or_diff($html, $args{result}, "result");
        }

        if ($args{test_after_export}) {
            $args{test_after_export}->(result=>$res);
        }
    };
}

1;
