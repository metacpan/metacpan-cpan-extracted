use strict;
use warnings;

use Test::More;
use List::Util qw(shuffle);

use FindBin qw($Bin);
use File::Basename qw(basename);

plan skip_all => "Crashes in 5.8" if $] < 5.010;

# Re-run all the tests.  This way we can catch stuff like
# stack corruptions or weird interactions in more complex
# programs.  Particularly fun in >5.18, with threads
# enabled.

my @files = grep { !/\Q11-all.t\E/ }
            # Handwritten TAP
            grep { !/\Q01-basics.t\E|\Q02-min.t\E/ }
            grep { /[0-9]{2}-/ } glob("$Bin/*.t");

@files = shuffle @files;

diag(join ", ", map { basename($_) } @files) if $ENV{RELEASE_TESTING};
my $pkg = "a";
for my $file (@files) {
    my ($e, $r);
    my $x = "...and it left the eval normally";
    
    TODO: {
        local $TODO = "Need to diagnose"
            if $file =~ /\Qdie.t/;
        subtest $file => sub {
            # Can't test $r and $e in here, because the do'd
            # test file called done_testing
            $r = eval qq{
                package Params::Lazy::Tests::$pkg;
                do q{$file};
                \$x;
            };
            $e = $@;
        };
    }
    is($e, '', "no errors from " . basename($file));
    is($r, $x, $x);
    $pkg++;
}

done_testing;
