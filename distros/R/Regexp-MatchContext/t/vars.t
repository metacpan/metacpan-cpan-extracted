use Test::More 'no_plan';
use Regexp::MatchContext -vars;

my $str = 'foobarbaz';

$str =~ m/ bar (?p)/x;

is $PREMATCH,  'foo'     =>    '$PREMATCH set correctly';
is $MATCH,     'bar'     =>    '$MATCH set correctly';
is $POSTMATCH, 'baz'     =>    '$POSTMATCH set correctly';

$str =~ m/ bar /x;

ok !defined $PREMATCH,  =>    '$PREMATCH unset correctly';
ok !defined $MATCH,     =>    '$MATCH unset correctly';
ok !defined $POSTMATCH, =>    '$POSTMATCH unset correctly';

$str =~ m/ baz (?p)/x;

is $PREMATCH,  'foobar'  =>    '$PREMATCH set correctly again';
is $MATCH,     'baz'     =>    '$MATCH set correctly again';
is $POSTMATCH, ''        =>    '$POSTMATCH set correctly again';

$str =~ m/ qux (?p)/x;

is $PREMATCH,  'foobar'  =>    '$PREMATCH left correctly on fail';
is $MATCH,     'baz'     =>    '$MATCH left correctly on fail';
is $POSTMATCH, ''        =>    '$POSTMATCH left correctly on fail';

$str =~ m/ foo (?p)/x;

is $PREMATCH,  ''        =>    '$PREMATCH set correctly yet again';
is $MATCH,     'foo'     =>    '$MATCH set correctly yet again';
is $POSTMATCH, 'barbaz'  =>    '$POSTMATCH set correctly yet again';

$str =~ m/ foobarbaz (?p)/x;

is $PREMATCH,  ''           =>    '$PREMATCH set correctly once again';
is $MATCH,     'foobarbaz'  =>    '$MATCH set correctly once again';
is $POSTMATCH, ''           =>    '$POSTMATCH set correctly once again';

$str =~ m/ bar /x;

ok !defined $PREMATCH,  =>    '$PREMATCH unset correctly again';
ok !defined $MATCH,     =>    '$MATCH unset correctly again';
ok !defined $POSTMATCH, =>    '$POSTMATCH unset correctly again';


$str =~ m/ bar (?p)/x;

$PREMATCH = '111';
is $str, '111barbaz'        => '$PREMATCH assignment worked';

$MATCH = '222';
is $str, '111222baz'        => '$MATCH assignment worked';

$POSTMATCH = '333';
is $str, '111222333'        => '$POSTMATCH assignment worked';


$str = 'foobarbaz';
$str =~ m/ bar (?p)/x;

$POSTMATCH = '33';
is $str, 'foobar33'        => '$POSTMATCH assignment worked again';

$PREMATCH = '1111';
is $str, '1111bar33'       => '$PREMATCH assignment worked again';

$MATCH = '222';
is $str, '111122233'       => '$MATCH assignment worked again';

$str = 'foobarbaz';
$str =~ m/ bar /x;

ok !defined eval{ $PREMATCH = '1'; 1 }  => 'Bad $PREMATCH assignment failed';
is substr($@,0,47), q{Can't assign to $PREMATCH because the preceding}
                                        => 'Correct $PREMATCH error';

ok !defined eval{ $MATCH = '1'; 1 }  => 'Bad $MATCH assignment failed';
is substr($@,0,44), q{Can't assign to $MATCH because the preceding}
                                        => 'Correct $MATCH error';

ok !defined eval{ $POSTMATCH = '1'; 1 }  => 'Bad $POSTMATCH assignment failed';
is substr($@,0,48), q{Can't assign to $POSTMATCH because the preceding}
                                        => 'Correct $POSTMATCH error';

