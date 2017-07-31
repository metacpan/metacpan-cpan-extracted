use strict;
use warnings;
use Test::More;

# Most use eval() if the OS is not supported and import() is invoked
BEGIN {
    eval { require Siebel::AssertOS };
}
can_ok( 'Siebel::AssertOS', qw(die_if_os_isnt die_unsupported os_is import) );
done_testing;
