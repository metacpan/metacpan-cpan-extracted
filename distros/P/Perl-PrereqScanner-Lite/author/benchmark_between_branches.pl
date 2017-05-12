#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark::Forking qw/:all/;

my $filename = $ARGV[0];
my $code = sub {
    my $filename = "lib/Perl/PrereqScanner/Lite.pm";
    my $p = Perl::PrereqScanner::Lite->new;
    $p->scan_file($filename);
};

cmpthese(1000, {
    'master' => sub {
        unless ($INC{"Perl/PrereqScanner/Lite.pm"}) {
            eval qq{use lib 'master/lib/perl5'};
            eval qq{use Perl::PrereqScanner::Lite};
        }
        $code->();
    },
    'feature' => sub {
        unless ($INC{"Perl/PrereqScanner/Lite.pm"}) {
            eval qq{use lib 'feature/lib/perl5'};
            eval qq{use Perl::PrereqScanner::Lite};
        }
        $code->();
    },
});
