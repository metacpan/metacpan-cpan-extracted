use Test::More tests => 7;
use strict;
$^W = 1;

BEGIN { use_ok 'Regexp::Common', 'Email::Address' };
use_ok 'Email::Address';

my $valid   = q[Casey West <casey@geeknest.com>];
my $invalid = q[@bar.com];

ok  $valid   =~ /$RE{Email}{Address}/, 'valid is valid';
ok !($invalid =~ /$RE{Email}{Address}/), 'invalid is invalid';

$valid =~ /$RE{Email}{Address}{-keep}/;
is $1, $valid, 'matches is the same';

my ($address) = Email::Address->parse($1);
is $address->phrase, 'Casey West', 'parsed address returned';
is $address->address, 'casey@geeknest.com', 'parsed address returned';

