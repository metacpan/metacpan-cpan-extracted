#!perl
use strict;
use warnings FATAL => 'all';

use Test::More 0.98 tests => 4;
use Term::Chrome;

note("@{[ Blue / Yellow + Reset + Reverse ]}Text@{[ Reset ]}");
is("@{[ Blue / Yellow + Reset + Reverse ]}Text@{[ Reset ]}",
    "\e[;7;34;43mText\e[m",
    "Blue / Yellow + Reset + Reverse");

is("${ Red+Bold }", "\e[1;31m", 'deref: ${ Red+Bold }');
is("${ +Red }", "\e[31m", 'deref: ${ +Red }');
is("${( Red )}", "\e[31m", 'deref: ${( Red )}');
note("normal ${ Red+Bold } RED ${ +Reset } normal");

# The following line doesn't even compile on perl 5.8.3
#note ref(Blue / Yellow + Reset + Reverse);

