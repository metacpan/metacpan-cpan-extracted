use Test::More;
use strict;
use warnings;
use System::Command;

# Adapted from https://github.com/book/System-Command/issues/27
`perl -Ilib -MSystem::Command -e '
    my \$out = System::Command->new(qw($^X -e1))->stdout;
    exit 3;
'`;
is( $? >> 8, 3, "exit status not clobbered" );
done_testing;
