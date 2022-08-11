use warnings;
use strict;

use Test::More;

plan tests => 82;

use PPR::X;
use re 'eval';

my @valid_derefs = grep /\S/, split "\n", q{

        qq{ $sref->$* }

        qq{ $aref->$#* }
        qq{ $aref->@* }
        qq{ $aref->@[1,2,3] }

        qq{ $href->@{'a','b'} }


        qq{ $rref->$* }

        qq{ $href->{a}[1][2]{z} }
};

my @invalid_derefs = grep /\S/, split "\n", q{

        qq{ $aref->%[1..3] }

        qq{ $href->%* }
        qq{ $href->%{'a','b'} }

        qq{ $cref->() }
        qq{ $cref->&* }

        qq{ $rref->$*->$* }
        qq{ $rref->$*->@* }

        qq{ $gref->** }
        qq{ $gref->**->{IO} }
        qq{ $gref->**->**->{IO} }
        qq{ $gref->*{IO} }

        qq{ $obj->method }
        qq{ $obj->method() }
        qq{ $obj->$method }
        qq{ $obj->$method() }

        qq{ $href->{a}[1]('arg')[2]{z} }
        qq{ $href->method->[1]('arg')('arg2')->$method()->[2]{z}->**->$*->&*->$#* }

        qq{ $aref->@*->[0] }
        qq{ $aref->@*->%[1..3] }
        qq{ $aref->@*->%{'k1', 'k2'} }
        qq{ $aref->@*->method() }
        qq{ $aref->@*->$* }
        qq{ $aref->@*->** }

        qq{ $href->%*->@[1..3] }
        qq{ $href->%*->@{'k1', 'k2'} }
        qq{ $href->%*->method() }
        qq{ $href->%*->$* }
        qq{ $href->%*->** }
        qq{ $aref->@*->[1] }
        qq{ $aref->@*->@[1..3] }
        qq{ $aref->@*->@{'k1', 'k2'} }

        qq{ $href->%*->{k} }
        qq{ $href->%*->%[1..3] }
        qq{ $href->%*->%{'k1', 'k2'} }
};

for my $deref (@valid_derefs) {
    next if $deref =~ m{\A \s* \#}xms;
    my ($full_deref) =  $deref =~ m{\A \s* qq\{ \s* (.*?) \s* \} \s* \Z}xms;

    our $postfix = undef;
    ok $deref =~ qr{ \A \s* (?&PerlQuotelikeQQ) \s* \Z
                     (?(DEFINE)
                         (?<PerlScalarAccessNoSpace>
                             ( (?&PerlStdScalarAccessNoSpace) )
                             (?{ $postfix = $^N; })
                         )
                     )
                     $PPR::X::GRAMMAR
                    }xms
                               => "Valid: $deref";

    is $postfix, $full_deref => "    and postderef matched appropriately";
}

for my $deref (@invalid_derefs) {
    next if $deref =~ m{\A \s* \#}xms;
    my ($full_deref) =  $deref =~ m{\A \s* qq\{ \s* (.*?) \s* \} \s* \Z}xms;

    our $postfix = undef;
    ok $deref =~ qr{ \A \s* (?&PerlQuotelikeQQ) \s* \Z
                     (?(DEFINE)
                         (?<PerlScalarAccessNoSpace>
                             ( (?&PerlStdScalarAccessNoSpace) )
                             (?{ $postfix = $^N; })
                         )
                     )
                     $PPR::X::GRAMMAR
                    }xms
                               => "Invalid: $deref";

    isnt $postfix, $full_deref => "    and postderef correctly failed to match";
}


done_testing();


