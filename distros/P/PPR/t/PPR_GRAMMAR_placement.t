use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 3;

use PPR;

my $source_code = q{
<<<<<<A;1

42
A
.
<<A . <<A;
)
A
]]]
A
say
<<X, qq!at
line 1 (in heredoc!)
X
line 3\n!;
};

ok $source_code =~ m{ \A (?&PerlDocument) \Z  $PPR::GRAMMAR }x => '$PPR::GRAMMAR at end';

ok $source_code =~ m{ $PPR::GRAMMAR  \A (?&PerlDocument) \Z }x => '$PPR::GRAMMAR at start';

ok $source_code =~ m{ \A $PPR::GRAMMAR (?&PerlDocument) \Z  }x => '$PPR::GRAMMAR in middle';


done_testing();

