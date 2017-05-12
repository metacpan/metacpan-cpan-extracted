use strict;
use warnings;
use Test::More;
use Regexp::Flow 're_matches', 're_substitutions';

subtest 'matches' => sub {
my $count;
re_matches ('abcd', qr/\w/, sub{$count++});
is($count,4, 'code executes');

$count = 0;
re_matches ('abcd', qr/\w/, sub{$count++; shift->last;});
is($count,1, 'last works');

ok (re_matches ('a', 'A', 'i'), 'i flag works');

$count = 0;
my $results = re_matches ('abcd', qr/\w/, sub{
    $count++;
    my $rr = shift;
    $rr->last if $rr->match eq 'c';
}, 'pg');
is($count,3, 'last+flags works');
ok ($results == 3, 'results numerically equals ok');

$results = re_matches ('foo','bar');
ok ((!$results), 'results are boolean false when no match');
};

subtest substitutions => sub {

my $count = 0;
my $string = 'abcd';
my $results = re_substitutions ($string, qr/\w/, sub{
    $count++;
    my $rr = shift;
    $rr->last if $rr->match eq 'c';
    'x';
}, 'pg');
is($count, 3, 'last+flags works');
is($string, 'xxxd', 'modified string');

};
done_testing;


