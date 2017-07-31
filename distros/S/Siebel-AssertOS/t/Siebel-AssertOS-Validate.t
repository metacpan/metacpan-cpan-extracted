use warnings;
use strict;
use Test::More;
use Siebel::AssertOS::Validate qw(os_is);

note(
"Cannot include Linux in the list because the distribution might not be supported"
);
for my $os_name (qw(MSWin32 aix solaris)) {
    ok( os_is($os_name), "$os_name is supported" );
}
is( os_is('plan9'), 0, 'plan9 is not a supported OS' );
done_testing;
