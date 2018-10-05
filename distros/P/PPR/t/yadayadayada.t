use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 3;


use PPR;

my $Perl_document = qr{
    \A (?&PerlDocument) \Z  $PPR::GRAMMAR
}xms;

ok 'sub foo {...}'                              =~ $Perl_document => 'Pure yada';
ok 'sub foo { say "partial"; ... ; etcetera; }' =~ $Perl_document => 'Partial yada';

ok 'sub foo { say "partial", ...}'              !~ $Perl_document => 'Not an expression';


done_testing();

