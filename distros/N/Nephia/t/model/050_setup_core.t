use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp 'tempdir';
use File::Spec;
use Capture::Tiny 'capture';
use Nephia::Setup;

my $tempdir = tempdir(CLEANUP => 1);
my $setup = Nephia::Setup->new(appname => 'MyApp::Web', approot => $tempdir);

subtest basic => sub {
    isa_ok $setup, 'Nephia::Setup';
    is $setup->appname, 'MyApp::Web';
    is_deeply [$setup->approot], [$tempdir];
    is_deeply [$setup->classfile], [qw/lib MyApp Web.pm/];
    isa_ok $setup->action_chain, 'Nephia::Chain';
    my @actions = $setup->action_chain;
    is_deeply [@actions], [];
    is_deeply $setup->deps, {
        requires => ['Nephia' => 0],
        test => {
            requires => ['Test::More' => 0],
        },
    };
    isa_ok $setup->meta_tmpl, 'Nephia::MetaTemplate';
};

subtest cpanfile => sub {
    my $cpanfile = $setup->cpanfile;
    like $cpanfile, qr/requires \'Nephia\' \=> 0\;/;
    like $cpanfile, qr/on \'test\' \=> sub \{\n    requires \'Test\:\:More\' \=> 0\;\n}\;/;
};

subtest create => sub {
    $setup->makepath();
    ok -d File::Spec->catdir( $setup->approot ), 'approot exists';

    $setup->makepath(qw/foo bar/);
    ok -d File::Spec->catdir( $setup->approot, qw/foo bar/ ), 'makepath';

    $setup->spew(qw/foo bar baz.txt/, $setup->cpanfile);
    ok -e File::Spec->catfile( $setup->approot, qw/foo bar baz.txt/ ), 'spew';
};

subtest template => sub {
    is $setup->process_template('foobar {{$self->appname}}'), 'foobar MyApp::Web', 'process_template';
};

subtest notification => sub {
    my ($stdout, $stderr) = capture {$setup->diag('foobar')};
    is $stderr, "foobar\n", 'diag';
};

subtest do_task => sub {
    my ($stdout, $stderr) = capture { $setup->do_task };
    like $stderr, qr/Begin to setup MyApp\:\:Web/;
    like $stderr, qr/Setup finished/;
};

subtest misc => sub {
    like $setup->_spaces_for_nest, qr/^$/;
    $setup->{nest} = 2;
    like $setup->_spaces_for_nest, qr/^ {4}$/;
    is $setup->_normalize_appname('MyApp::Web'), 'MyApp-Web';
    is_deeply $setup->_resolve_approot('MyApp::Web'), [qw/. MyApp-Web/];
    is $setup->_plugin_name_normalize('FooBar'), 'Nephia::Setup::Plugin::FooBar';
    is $setup->_plugin_name_normalize('Nephia::Setup::Plugin::FooBar'), 'Nephia::Setup::Plugin::FooBar';
};

done_testing;
