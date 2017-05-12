use strict;
use warnings;
use Test::More;
use Test::Builder;
use Module::Starter qw(Module::Starter::TOSHIOITO);
use Module::CPANfile;

if($ENV{RELEASE_TESTING}) {
    plan "skip_all", "File generation test is skipped while RELEASE_TESTING";
    exit 0;
}

my $MOD_NAME = 'Module::Starter::TOSHIOITO';
my $DIST_NAME = $MOD_NAME; $DIST_NAME =~ s/::/-/g;

sub check_diff {
    my ($relative_path) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $exp = $relative_path;
    my $got = "$DIST_NAME/$relative_path";
    if(! -e $exp) {
        die "Expected file $exp does not exist";
    }
    if(!ok(-e $got, "$got should be generated")) {
        return;
    }
    my $diff = `diff -u $got $exp`;
    is $diff, "", "file $relative_path OK";
}

ok(!-e $DIST_NAME, "$DIST_NAME should not exist before this test") or do {
    done_testing;
    exit 0;
};

Module::Starter->create_distro(
    modules => [$MOD_NAME],
    builder => 'Module::Build',
    author  => 'Toshio Ito',
    email   => 'toshioito@cpan.org',
    github_user_name => 'debug-ito',
);

foreach my $file (qw(Build.PL .gitignore .travis.yml MANIFEST.SKIP)) {
    check_diff $file;
}

foreach my $file (qw(README Changes lib/Module/Starter/TOSHIOITO.pm)) {
    my $path = "$DIST_NAME/$file";
    ok(-f $path, "$path generated OK");
}

{
    my $got_prereqs = Module::CPANfile->load("$DIST_NAME/cpanfile")->prereq_specs;
    my $exp_prereqs = Module::CPANfile->load("cpanfile")->prereq_specs;
    is_deeply($got_prereqs->{configure}{requires}, $exp_prereqs->{configure}{requires},
              "generated cpanfile configure_requires OK");
}


done_testing;
