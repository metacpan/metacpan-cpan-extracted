#!perl -T

use strict;
use warnings;

use Test::More tests => 34;

use Sub::Nary;

my $sn = Sub::Nary->new();

my ($x, %h);

my @tests = (
 [ sub { delete $h{foo} },             1 ],
 [ sub { delete @h{qw/foo bar baz/} }, 3 ],

 [ sub { return <$x> }, 'list' ],

 [ sub { -f $0, -r $0 }, 2 ],

 [ sub { return caller 0 },  sub { my @a = caller 0; scalar @a }->() ],
 [ sub { return localtime }, do { my @a = localtime; scalar @a } ],
 [ sub { gmtime },           do { my @a = gmtime; scalar @a } ],

 [ sub { each %h }, { 0 => 0.5, 2 => 0.5 } ],
 [ sub { stat $0 }, { 0 => 0.5, 13 => 0.5 } ],

 [ sub { do { getpwnam 'root' } },            { 0 => 0.5, 10 => 0.5 } ],
 [ sub { 1; getpwuid '0' },                   { 0 => 0.5, 10 => 0.5 } ],
 [ sub { eval { return getpwent } },          { 0 => 0.5, 10 => 0.5 } ],

 [ sub { do { getgrnam 'root' } },            { 0 => 0.5, 4 => 0.5 } ],
 [ sub { 1; getgrgid '0' },                   { 0 => 0.5, 4 => 0.5 } ],
 [ sub { eval { return getgrent } },          { 0 => 0.5, 4 => 0.5 } ],

 [ sub { do { gethostbyname 'localhost' } },  'list' ],
 [ sub { 1; gethostbyaddr '', '' },           'list' ],
 [ sub { eval { return gethostent } },        'list' ],

 [ sub { do { getnetbyname '' } },            { 0 => 0.5, 4 => 0.5 } ],
 [ sub { 1; getnetbyaddr '', '' },            { 0 => 0.5, 4 => 0.5 } ],
 [ sub { eval { return getnetent } },         { 0 => 0.5, 4 => 0.5 } ],

 [ sub { do { getprotobyname 'tcp' } },       { 0 => 0.5, 3 => 0.5 } ],
 [ sub { 1; getprotobynumber 6 },             { 0 => 0.5, 3 => 0.5 } ],
 [ sub { eval { return getprotoent } },       { 0 => 0.5, 3 => 0.5 } ],

 [ sub { do { getservbyname 'ssh', 'tcp' } }, { 0 => 0.5, 4 => 0.5 } ],
 [ sub { 1; getservbyport 22, 'tcp' },        { 0 => 0.5, 4 => 0.5 } ],
 [ sub { eval { return getservent } },        { 0 => 0.5, 4 => 0.5 } ],

 [ sub { endpwent },    1 ],
 [ sub { endgrent },    1 ],
 [ sub { endhostent },  1 ],
 [ sub { endnetent },   1 ],
 [ sub { endprotoent }, 1 ],
 [ sub { endservent },  1 ],

 [ sub { <*.*> }, 1 ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'ops test ' . $i);
 ++$i;
}
