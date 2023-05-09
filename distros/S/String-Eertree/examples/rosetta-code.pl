#!/usr/bin/perl
use warnings;
use strict;

use String::Eertree;

sub rosetta_code {
    my ($str) = @_;
    no strict 'vars';
    no warnings 'once';

    for $n (1 .. length($str)) {
       for $m (1 .. length($str)) {
          $strrev = "";
          $strpal = substr($str, $n-1, $m);
          if ($strpal ne "") {
             for $p (reverse 1 .. length($strpal)) {
                $strrev .= substr($strpal, $p-1, 1);
             }
             ($strpal eq $strrev) and push @pal, $strpal;
          }
       }
    }
    return grep {not $seen{$_}++} @pal
}

my $string = join 'x', ('abcdcba') x 10;

my $tree = 'String::Eertree'->new(string => $string);

use Test2::V0;
plan 1;
is [$tree->uniq_palindromes],
    bag { item $_ for rosetta_code($string);
          end() },
    'same';

use Benchmark qw{ cmpthese };
cmpthese(-3, {
    rosetta => sub { rosetta_code($string) },
    eertree => sub { 'String::Eertree'->new(string => $string)
                         ->uniq_palindromes },
});
__END__
          Rate rosetta eertree
rosetta 46.2/s      --    -97%
eertree 1755/s   3696%      --
