#!perl
use Test::More tests => 3;
use Devel::Cover::DB;

my @criteria = qw(subroutine statement branch);
my $db = new Devel::Cover::DB db => 'cover_db';
merge_runs $db;
calculate_summary $db map { $_ => 1 } @criteria;

for (@criteria) {
    my $cr = $$db{summary}{Total}{$_};
    ok $$cr{covered} == $$cr{total}, sprintf "\u$_ coverage is %.3g%% (%d/%d)", @$cr{qw(percentage covered total)};
}
