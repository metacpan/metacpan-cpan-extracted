#!perl -T

use Test::More;
use String::Palindrome qw/ is_palindrome /;

use Data::Dumper;


#  Simple checks
my @ok    = qw/ qwerrewq 123454321 12344321 axc3223cxa a aa aaaaaaa aaabaaa /;
my @nok   = qw/ asdf fejal aabab asdf 1343 /;
my @undef = ([], {a => 1}, undef);


#  Array checks
my @ok_ref  = ([@ok,  reverse @ok]);
my @nok_ref = ([@nok, @nok]);

push @ok_ref,  [split //, $_]  for  @ok;
push @nok_ref, [split //, $_]  for  @nok;

push @ok_ref,  ([qw/ hi  bye  ted  bye hi/], [qw/ hello  world  world  hello /], [undef, 1, 1, undef], [undef, 1, undef], [1, undef, 1]);
push @nok_ref, ([qw/ hi  bye  ted  bye ih/], [qw/ hello  world  helol /], [undef, 1, 1], [1, 1, undef]);


#  Array refs
my $a = [1,2,3];
my $b = [1,2,3];
my $c = {a=>1,b=>2};

push @ok_ref,  ([$a, $a], [$b, $b, $b], [$a, $b, $c, $c, $b, $a]);
push @nok_ref, ([$a, $b], [$b, $a],     [$a, $c]                );


#  POD examples
push @ok,  'abccba';
push @nok, 'abcdef';


#  Seperate "blank" check
push @nok, '';


#  Plan our tests
plan tests => @ok + (@ok_ref * 2) + @nok + (@nok_ref * 2) + @undef;


#  Test OKs
for  my $ok  (@ok) {
    is(is_palindrome($ok), 1, "($ok) not reported as a palindrome");
}

for  my $ok  ( @ok_ref ) {
    is(is_palindrome($ok),  1, sprintf('(%s) [array_ref] not reported as a palindrome', Dumper $ok));
    is(is_palindrome(@$ok), 1, sprintf('(%s) [array] not reported as a palindrome',     Dumper $ok));
}


#  Test Not OKs
for  my $nok  (@nok) {
    is(is_palindrome($nok), 0, "($nok) reported as a palindrome");
}

for  my $nok  ( @nok_ref ) {
    is(is_palindrome($nok),  0, sprintf('(%s) [array_ref] reported as a palindrome', Dumper $nok));
    is(is_palindrome(@$nok), 0, sprintf('(%s) [array] reported as a palindrome',     Dumper $nok));
}


#  Test Undefs
for  my $undef  (@undef) {
    is(is_palindrome($undef), undef, "item not reported as a undef");
}
