use warnings;
use strict;

use Test::More;

plan tests => 2;

use PPR;

my $code = <<'_EOT_';
print <<'EOF'; format STDOUT =
Where's that format?
EOF
Foo bar
.
write;
_EOT_

ok $code =~ m{ \A (?&PerlDocument) \z $PPR::GRAMMAR }x
                    => 'Matched document';

ok $code =~ m{
               \A print             (?&PerlOWS)
                  (?&PerlHeredoc) ; (?&PerlOWS)
                  (?&PerlFormat)    (?&PerlOWS)
                  write;
               \Z

               $PPR::GRAMMAR
             }x => 'Matched pieces';

done_testing();


