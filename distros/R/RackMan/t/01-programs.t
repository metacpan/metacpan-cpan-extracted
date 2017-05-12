#!perl
use strict;
use Config;
use File::Spec::Functions;
use Test::More;


plan skip_all => "Test::Cmd not available" unless eval "use Test::Cmd; 1";

my %programs = (
    rack            => "RackManager",
   "cisco-status"   => "Cisco switch status",
   "cfengine-tags"  => "Cfengine tags generator",
   "racktables-check"   => "RackTables consistency check",
);


# extract the list of prereqs
my $prereq;
open my $fh, "<", "Makefile.PL";
my $PL = do { local $/, <$fh> };
$PL =~ /PREREQ_PM\s*=>\s*(\{[^}]+\})/ms and $prereq = eval "no strict; $1";

# test that the interpreter will find the prereq modules
my $perl = join " ", $Config{perlpath}, map "-I$_", @INC;

for my $module (sort keys %$prereq) {
    my $cmd = Test::Cmd->new(prog => $perl, workdir => "");
    my $r = $cmd->run(args => "-M$module -e1");
    $r == 0 or plan skip_all => "can't load module $module with Test::Cmd";
}


plan tests => 6 * keys %programs;

for my $command (sort keys %programs) {
    my $program = $programs{$command};
    my $cmdpath = -d "blib" ? catfile("blib", "script", $command)
                            : catfile("bin", $command);

    my $cmd = Test::Cmd->new(prog => $cmdpath, workdir => "", interpreter => $perl);
    ok( $cmd, "created Test::Cmd object for $command" );

    # checking option --version
    $cmd->run(args => '--version', 'chdir' => $cmd->curdir);
    is( $?, 0, "exec: $command --version" );
    like( $cmd->stdout, qr/^$program v\d+\.\d+$/i, "  => checking version output" );

    # checking usage
    my $fakeopt = "this-is-not-an-option";
    $cmd->run(args => "--$fakeopt", 'chdir' => $cmd->curdir);
    is( $?, 0, "exec: $command --$fakeopt" );
    like( $cmd->stderr, qr/^Unknown option: $fakeopt$/, "  => checking error" );
    like( $cmd->stdout, qr/^Usage:\s+$command /ms, "  => checking usage");
}
