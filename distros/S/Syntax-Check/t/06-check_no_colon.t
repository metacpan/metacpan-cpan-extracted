use strict;
use warnings;
use feature 'say';

use Capture::Tiny qw(:all);
use Data::Dumper;
use File::Path qw(remove_tree);
use Test::More;

BEGIN {
    use_ok( 'Syntax::Check' ) || print "Bail out!\n";
}

my $m = 'Syntax::Check';
my $f = 't/data/no_colons.pl';

{
    my ($out, $err) = capture {
        $m->new(file => $f, verbose => 1)->check;
    };

    like $err, qr/syntax OK/, "no colon module ok";
    like $out, qr/pragma/, "no colon verbose ok";
}

done_testing;
