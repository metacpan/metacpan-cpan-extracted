#!perl
use strict;
# print all the punctuation vars
print <<END;
\$& $&
\$` $`
\$' $'
\$+ $+

\$. tested elsewhere
\$/ $/

\$| $|
\$, $,
\$\ $\

\$" $"
\$; $;

\$% $%
\$= $=
\$- TODO
\$~ $~
\$^ $^
\$: $:
\$^L $^L

\$? $?
\$! $!
\$^E $^E
\$@ $@

\$\$ tested elsewhere
\$< $<
\$> $>
\$( $(
\$) $)
\$0 $0

\$] $]

\$^A $^A
\$^C $^C
\$^D $^D
\$^F hightly dependant on weather
\$^I $^I
\$^P $^P
\$^R $^R
\$^S can't affect
\$^T can't test here
\$^W $^W
\$^X varies wildly
\$^O $^O
END
