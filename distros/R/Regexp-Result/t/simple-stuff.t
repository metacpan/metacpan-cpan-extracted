use strict;
use warnings;
use Test::More;
use Regexp::Result;

sub rr {Regexp::Result->new()};

my $foo = "In the beginning, there was the Word.";

$foo =~ m/(In).*(Wo)/p;

my $rr = rr;

is $rr->c(1), 'In', 'can get $1';

$foo =~ m/(the) beginning/p;

is rr->c(1), 'the', 'second rr call uses correct info';

is $rr->c(1), 'In', 'original rr info is retained';

is rr->prematch, 'In ', 'prematch';

is $rr->postmatch, 'rd.', 'postmatch';

is rr->match, 'the beginning', 'match';

{
    $foo =~ /(The)|(the)/;
    ok(!defined rr->c(1), '$1 does not exist in /(nomatch)|(match)/' );
    is(rr->c(2), 'the', '$2 exists in /(nomatch)|(match)/' );
}

done_testing();