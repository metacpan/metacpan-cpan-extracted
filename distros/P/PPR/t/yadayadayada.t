use warnings;
use strict;

use Test::More;

plan tests => 3;


use PPR;

my $Perl_document = qr{
    ^ (?&PerlDocument) $  $PPR::GRAMMAR
}xms;

ok 'sub foo {...}'                              =~ $Perl_document => 'Pure yada';
ok 'sub foo { say "partial"; ... ; etcetera; }' =~ $Perl_document => 'Partial yada';

ok 'sub foo { say "partial", ...}'              !~ $Perl_document => 'Not an expression';


done_testing();

