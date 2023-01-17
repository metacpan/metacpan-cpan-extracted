use Test2::V0;

use Path::Tiny;

use String::License;

plan 1;

my $string  = path('t/devscripts/regexp-killer.c')->slurp_utf8;
my $license = String::License->new( string => $string )->as_text;

is $license, 'UNKNOWN', 'regexp killer';

done_testing;
