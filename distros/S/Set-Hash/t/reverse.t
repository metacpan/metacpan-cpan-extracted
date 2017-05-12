use Test::More qw(no_plan);
BEGIN{
   use_ok('Set::Hash');
}
require_ok('Set::Hash');

my $answer1 = {dan=>"name",blonde=>"hair",blue=>"eyes"};
my $answer2 = {name=>"dan",hair=>"blonde",eyes=>"blue"};

my $sh1 = Set::Hash->new(qw/name dan hair blonde eyes blue/);

my %new = $sh1->reverse;
my $new = $sh1->reverse;

eq_hash(\%new,$answer1);
eq_hash($new,$answer1);

$sh1->reverse;

my %orig = $sh1->reverse;
my $orig = $sh1->reverse;

eq_hash(\%orig,$answer2);
eq_hash($orig,$answer2);
