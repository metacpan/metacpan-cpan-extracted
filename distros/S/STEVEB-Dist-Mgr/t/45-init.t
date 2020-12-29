use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Hook::Output::Tiny;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my $mods = [qw(Test::Module)];
my $cwd = getcwd();

my $new_mod_file = "lib/Test/Module.pm";

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => $mods,
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

remove_init();

# bad directory
{
    is eval {
        init();
        1
    }, undef, "croak if we try to damage our own repo";
    like $@, qr/Can't run init\(\)/, "...and error is sane";
    after();
}

# params
{
    # no modules
    before();
    is eval { init(); 1 }, undef, "need modules param ok";
    like $@, qr/requires 'modules'/, "...and error is sane";
    after();

    # no author
    before();
    is eval { init(modules => $mods); 1 }, undef, "need author param ok";
    like $@, qr/requires 'author'/, "...and error is sane";
    after();

    # no email
    before();
    is eval { init(modules => $mods, author => 'stevieb9'); 1 }, undef, "need email param ok";
    like $@, qr/requires 'email'/, "...and error is sane";
    after();
}

# good init
{
    before();

    $h->hook('stderr');
    init(%module_args);
    $h->unhook('stderr');

    my @e = $h->stderr;

    is $e[0], 'Added to MANIFEST: Changes', "line 0 of stderr ok";
    is $e[1], 'Added to MANIFEST: ignore.txt', "line 1 of stderr ok";
    is $e[2], 'Added to MANIFEST: lib/Test/Module.pm', "line 2 of stderr ok";
    is $e[3], 'Added to MANIFEST: Makefile.PL', "line 3 of stderr ok";
    is $e[4], 'Added to MANIFEST: MANIFEST', "line 4 of stderr ok";
    is $e[5], 'Added to MANIFEST: README', "line 5 of stderr ok";
    is $e[6], 'Added to MANIFEST: t/00-load.t', "line 6 of stderr ok";
    is $e[7], 'Added to MANIFEST: t/manifest.t', "line 7 of stderr ok";
    is $e[8], 'Added to MANIFEST: t/pod-coverage.t', "line 8 of stderr ok";
    is $e[9], 'Added to MANIFEST: t/pod.t', "line 9 of stderr ok";
    is $e[10], 'Added to MANIFEST: xt/boilerplate.t', "line 10 of stderr ok";
    is defined $e[11], '', "...and that's all folks!";

    # check that the new module file is the same as our baseline template

    chdir 'Test-Module' or die $!;
    like getcwd(), qr/Test-Module$/, "in new module directory ok";

    open my $orig_fh, '<', "$cwd/$orig/Module.tpl" or die $!;
    open my $new_fh, '<', $new_mod_file or die $!;

    my @orig_tpl = <$orig_fh>;
    my @new_tpl  = <$new_fh>;

    close $orig_fh;
    close $new_fh;

    for (0..$#new_tpl) {
        is $new_tpl[$_], $orig_tpl[$_], "module template line $_ matches ok";
    }

    chdir '..' or die $!;
    like getcwd(), qr/init$/, "back in 'init' directory ok";

    check();
    after();
}

remove_init();

done_testing;

sub before {
    like $cwd, qr/steveb-dist-mgr/, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    if (! -d 'init') {
        mkdir 'init' or die $!;
    }

    is -d 'init', 1, "'init' dir created ok";

    chdir 'init' or die $!;
    like getcwd(), qr/$work\/init$/, "in $work/init directory ok";
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/steveb-dist-mgr/, "back in root directory ok";
}
sub check {
    is -d 'Test-Module', 1, "Test-Module directory created ok";

    chdir 'Test-Module' or die $!;
    like getcwd(), qr/Test-Module/, "in Test-Module dir ok";
}

