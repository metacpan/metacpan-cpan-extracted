use Test::More;
use strict;
use warnings;
use System::Command;

# Adapted from https://github.com/book/System-Command/issues/27
my $quote = q|'|;
`$^X -Ilib -MSystem::Command -e $quote
    my \$out = System::Command->new(qw($^X -e1))->stdout;
    exit 3;
$quote`;
is( $? >> 8, 3, "exit status not clobbered" );
done_testing;
