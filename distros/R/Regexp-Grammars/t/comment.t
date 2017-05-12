use 5.010;
use warnings;
use Test::More 'no_plan';

my $parser = do{
    use Regexp::Grammars;
    qr{
        ^ <test> $   (?# <notarule> )

        <rule: test>
            a test     # some <other> here
    }xms;
};

my $target = q{a test};

ok +($target =~ $parser)    => 'Matched';
