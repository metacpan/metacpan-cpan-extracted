use Module::Setup::Test::Utils;
use Test::More;

# this code is a variation of Module-Setup/t/030_plugin/vc_git.t for VC::Bazaar.

system 'bzr', '--version';
plan skip_all => "bzr is not installed." if $?;

plan tests => 26;

module_setup { init => 1 };

dialog {
    my($self, $msg, $default) = @_;
    'n';
};
module_setup { target => 1, plugins => ['VC::Bazaar'] }, 'VC::Bazaar0';
ok !-f target_dir('VC-Bazaar')->file('.bzrignore');
ok !-d target_dir('VC-Bazaar', '.bzr');

dialog {
    my($self, $msg, $default) = @_;
    return 'n' if $msg !~ /bzr/i;
    like $msg, qr/Bzr init\?/;
    is $default, 'y';
    'y';
};

module_setup { target => 1, plugins => ['VC::Bazaar'] }, 'VC::Bazaar';
ok -f target_dir('VC-Bazaar')->file('.bzrignore');
ok -d target_dir('VC-Bazaar', '.bzr');

{
    my @tests = (
        [qw/bzr init/],
        [qw/bzr add/],
        [qw/bzr commit -m/, 'initial commit'],
    );
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        return 0 if @tests == 1 && $args[1] ne 'commit';
        my $cmds = shift @tests;
        is_deeply $cmds, \@args;
        return 0;
    };
    module_setup { target => 1, plugins => ['VC::Bazaar'] }, 'VC::Bazaar2';
}

{
    my @tests = (
        { cmds => [qw/bzr init/]                       , code => 1 },
        { cmds => [qw/bzr add/]												 , code => 2 },
        { cmds => [qw/bzr commit -m/, 'initial commit'], code => 3 },
    );
    my @stack_test;
    my @pre_cmds;
    no warnings 'redefine';
    local *Module::Setup::system = sub {
        my($self, @args) = @_;
        if (@pre_cmds) {
            my $cmds = shift @pre_cmds;
            is_deeply $cmds, \@args;
            return 0;
        }
        return 0 if @tests == 1 && $args[1] ne 'commit';
        my $cmds = shift @tests;
        is_deeply $cmds->{cmds}, \@args;
        push @stack_test, $cmds->{cmds};
        return $? = $cmds->{code};
    };
    for my $code (1..3) {
        local $@;
        @pre_cmds = @stack_test;
        eval { module_setup { target => 1, plugins => ['VC::Bazaar'] }, 'VC::Bazaar3_' . $code };
        like $@, qr/$code at /;
    }
}

