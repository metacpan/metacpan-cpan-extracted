use Test::More 'no_plan';
use Test::Deep;
use lib '../lib';
use NG;

my $f = new File;
isa_ok $f, 'File';

my $stat = File::fstat( '/tmp' );
isa_ok $stat, 'Hashtable';

is $stat->{mode}, '1777';
is $stat->{uid}, 0;

isa_ok $stat->{atime}, 'Time';
is $stat->{atime}->year, Time->new->now->year;
