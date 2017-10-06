use warnings;
use strict;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


plan tests => 2;

use PPR;

my $code = <<'_EOT_';
<<X, qq!at
line 1 (in heredoc!)
X
line 3\n!;
_EOT_

ok $code =~ m{ \A (?&PerlDocument) \z $PPR::GRAMMAR }x
                    => 'Matched document';

ok $code =~ m{
               \A (?&PerlHeredoc) , (?&PerlOWS)
                  (?&PerlString)    (?&PerlOWS)
                  ;
               \Z

               $PPR::GRAMMAR
             }x => 'Matched pieces';

done_testing();

