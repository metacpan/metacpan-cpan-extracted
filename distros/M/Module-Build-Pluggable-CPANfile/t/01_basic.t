use strict;
use warnings;
use utf8;
use Test::More;
use Test::Module::Build::Pluggable;
use Module::Build::Pluggable::CPANfile;
use version;
use Capture::Tiny ':all';
use File::Spec;

if ( $^O eq 'MSWin32' ) {
    plan skip_all => 'Skip test on Windows';
}

require Module::Build;
my $support_test_requries = 
    ( version->parse($Module::Build::VERSION) >= version->parse('0.4004') ) ? 1 : 0;

my $test = Test::Module::Build::Pluggable->new();
$test->write_file('Build.PL', <<'...');
use strict;
use Module::Build::Pluggable (
    'CPANfile',
);
my $builder = Module::Build::Pluggable->new(
    dist_name => 'Eg',
    dist_version => 0.01,
    dist_abstract => 'test',
    dynamic_config => 0,
    module_name => 'Eg',
    requires => {},
    provides => {},
    author => 1,
    dist_author => 'test',
);
$builder->create_build_script();
...

$test->write_file('cpanfile', <<'...');
requires 'LWP::UserAgent' => '6.02';
requires 'HTTP::Message'  => '6.04';
suggests 'JSON' => '2.53';
on 'test' => sub {
   requires 'Test::More'     => '0.98';
   requires 'Test::Requires' => '0.06';
};
...
$test->write_file('MANIFEST', <<'...');
Build.PL
MANIFEST
...

my $stderr = capture_stderr { $test->run_build_pl() };
like $stderr, qr/not support 'suggests'/;
my $meta = $test->read_file(File::Spec->catfile('_build','prereqs'));
ok($meta);
my $prereqs = eval $meta;

is_deeply( $prereqs->{build_requires}, $support_test_requries ? {
        'Module::Build::Pluggable::CPANfile' => $Module::Build::Pluggable::CPANfile::VERSION,
    } : {
        'Test::More'     => '0.98',
        'Test::Requires' => '0.06',
        'Module::Build::Pluggable::CPANfile' => $Module::Build::Pluggable::CPANfile::VERSION,
    }
);

SKIP : {
    skip "You have Module::Build < 0.4004",1 if !$support_test_requries;
    is_deeply( $prereqs->{test_requires}, {
        'Test::More'     => '0.98',
        'Test::Requires' => '0.06',
    });
}

is_deeply( $prereqs->{requires}, {
    'LWP::UserAgent' => '6.02',
    'HTTP::Message'  => '6.04', 
});

done_testing();


