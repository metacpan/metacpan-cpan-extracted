use strict;
use warnings;
use utf8;
use Test::More;
use Spellunker;
use Data::Dumper;

BEGIN { $ENV{PERL_SPELLUNKER_NO_USER_DICT} = 1 }

my $spellunker = Spellunker->new();
while (<DATA>) {
    next unless /\S/;
    chomp;
    my @bad = $spellunker->check_line($_);
    isnt(0+@bad, 0, $_);
    note Dumper(\@bad);
}

done_testing;

__DATA__
includs JSON::backportPP instead of JSON::PP.
In Teng, you simply use Teng::Schema's domain specific languaage to define a set of tables
If $table is specified, it set table infomation to result iterator.
