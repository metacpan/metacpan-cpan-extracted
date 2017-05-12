use 5.010;
use warnings;
use Test::More 'no_plan';

use List::Util qw< reduce >;

my $goodobj = do{
    use Regexp::Grammars;
    qr{
        <GoodObj>

        <objrule: GoodObj>
            obj
    }xms
};

my $badobj = do{
    use Regexp::Grammars;
    qr{
        <BadObj>

        <objrule: BadObj>
            obj
    }xms
};

close *STDERR;
ok 'obj' =~ $goodobj   => 'GoodObj';
ok 'obj' !~ $badobj    => 'BadObj';


package GoodObj;
sub new { bless {}, shift; }

package BadObj;
sub new { bless [], shift; }
