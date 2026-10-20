#!perl

# punk_mrows.h against a plain Perl oracle (xt/lib/RowsOracle.pm): 500 random
# filters and orderings over a random table with NULLs, mixed numbers and
# strings, and UTF-8; every result compared, and every ordering walked page
# by page through the `after` token.

use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../t/lib";
use Test::More;
use File::Temp ();
use File::Raw ();
use File::Raw::JSON ();
use RowsOracle ();
use Punk::Model::JSONFile ();

my $seed = $ENV{ORACLE_SEED} // time;
srand $seed;
diag "seed $seed";

my @words = ('alpha', 'Bravo', 'café', 'a_b', '10', '9', '', 'zeta%', 'Ünï');
sub val {
    my $r = rand;
    return undef if $r < 0.15;
    return int(rand 20) - 5 if $r < 0.5;
    return $words[rand @words];
}
my @rows = map +{ id => $_, a => val(), b => val(), c => val() }, 1 .. 60;

my $dir = File::Temp->newdir;
File::Raw::atomic_spew("$dir/t.json", File::Raw::JSON::file_json_encode({ t => \@rows }));
my $B = Punk::Model::JSONFile->new(database => { file => "$dir/t.json" }, table => 't',
    primary => 'id', columns => [qw(id a b c)]);
# the decoded rows, so the oracle sees exactly what the C sees
my $decoded = $B->document->{t};

my @ops = ('=', '!=', '<', '<=', '>', '>=', 'in', 'not_in', 'starts_with', 'like');
sub rand_term {
    my $op = $ops[rand @ops];
    my $v = val();
    if ($op eq 'in' || $op eq 'not_in') { return { $op => [ map val(), 0 .. int(rand 4) - 1 ] } }
    if ($op =~ /^(?:<|<=|>|>=|starts_with|like)$/) {
        $v = 'a' unless defined $v;
        $v = substr($v, 0, 2) . '%' if $op eq 'like' && rand > 0.5;
        return { $op => $v };
    }
    return rand > 0.5 ? $v : { $op => $v };
}

my $fails = 0;
for my $i (1 .. 500) {
    my %filter;
    $filter{ (qw(a b c))[rand 3] } = rand_term() for 1 .. int(rand 3);
    my @order = map [ (qw(a b c))[rand 3], int(rand 2) ], 1 .. int(rand 3);
    my %seen; @order = grep { !$seen{ $_->[0] }++ } @order;
    my $ob = @order ? [ map { ($_->[0], $_->[1] ? 'desc' : 'asc') } @order ] : undef;

    my $want = RowsOracle::search($decoded, 'id', \%filter, \@order);
    my (@got, $page);
    my $limit = 1 + int rand 7;
    do {
        $page = $B->search(\%filter, { limit => $limit, ($ob ? (order_by => $ob) : ()),
                                       ($page ? (after => $page->{next}) : ()) });
        push @got, map $_->{id}, @{ $page->{rows} };
    } while ($page->{has_more_data} && @got < 1000);
    my $count = $B->count(\%filter);
    if ("@got" ne "@$want" || $count != @$want) {
        $fails++;
        diag explain { filter => \%filter, order => $ob, want => $want, got => \@got, count => $count }
            if $fails <= 3;
    }
}
is $fails, 0, '500 random searches, paged through, agree with the oracle';

done_testing;
