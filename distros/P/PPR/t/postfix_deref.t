use warnings;
use strict;

use Test::More;

plan tests => 38;

use PPR;

my @valid_derefs = grep /\S/, split "\n", q{

        $sref->$*

        $aref->$#*
        $aref->@*
        $aref->@[1,2,3]
        $aref->%[1..3]

        $href->%*
        $href->%{'a','b'}
        $href->@{'a','b'}

        $cref->()
        $cref->&*

        $rref->$*->$*
        $rref->$*->@*

        $gref->**
        $gref->**->{IO}
        $gref->**->**->{IO}
        $gref->*{IO}

        $obj->method
        $obj->method()
        $obj->$method
        $obj->$method()

        # Composite look-ups, including elided arrows between brackets...
        $ref->{a}[1]('arg')[2]{z}
        $ref->method->[1]('arg')('arg2')->$method()->[2]{z}->**->$*->&*->$#*

        # These are all--believe it or not--legal (at least syntactically)...
        $aref->@*->%[1..3]
        $aref->@*->%{'k1', 'k2'}
        $aref->@*->method()
        $aref->@*->$*
        $aref->@*->**

        $href->%*->@[1..3]
        $href->%*->@{'k1', 'k2'}
        $href->%*->method()
        $href->%*->$*
        $href->%*->**
};

my @invalid_derefs = grep /\S/, split "\n", q{

        $aref->@*->[1]
        $aref->@*->@[1..3]
        $aref->@*->@{'k1', 'k2'}

        $href->%*->{k}
        $href->%*->%[1..3]
        $href->%*->%{'k1', 'k2'}
};

for my $deref (@valid_derefs) {
    next if $deref =~ m{\A \s* \#}xms;
    ok $deref =~ qr{ \A \s* (?&PerlPrefixPostfixTerm) \s* \Z $PPR::GRAMMAR}xms  => "Valid: $deref";
}

for my $deref (@invalid_derefs) {
    next if $deref =~ m{\A \s* \#}xms;
    ok $deref !~ qr{ \A \s* (?&PerlPrefixPostfixTerm) \s* \Z $PPR::GRAMMAR}xms  => "Invalid: $deref";
}


done_testing();

