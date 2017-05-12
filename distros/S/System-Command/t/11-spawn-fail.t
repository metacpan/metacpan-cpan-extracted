use strict;
use warnings;
use Test::More;
use System::Command;
use Config;

# do not test under Win32
plan skip_all => 'This test script  does not make sense under Win32'
    if $^O eq 'MSWin32';

my @fail = (
    {   cmdline => ['does-not-exist'],
        fail    => qr/^Can't exec\( does-not-exist \): /,
    },
);

plan tests => 2 * @fail;

for my $t (@fail) {

    # run the command
    my $cmd = eval { System::Command->new( @{ $t->{cmdline} } ) };
    ok( !$cmd, "command failed: @{ $t->{cmdline} }" );
    like( $@, $t->{fail}, '... expected error message' );

    # didn't fail?
    if ($cmd) {

        # get the output
        my $output = join '', $cmd->stdout->getlines();
        diag "output:\n", $output;

        # get the errput
        my $errput = join '', $cmd->stderr->getlines();
        diag "errput:\n", $errput;

        # close and check
        $cmd->close();
        diag "exit: " . $cmd->exit;
        diag "signal: " . $cmd->signal;
        diag "core: " . $cmd->core;
    }
}

