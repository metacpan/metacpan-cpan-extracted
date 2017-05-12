#!perl
use strict;
use warnings;
use Test::More tests => 20;
my $class = 'Module::Depends::Intrusive';
require_ok("Module::Depends");
require_ok($class);

my $our_requires = {
    'Class::Accessor::Chained' => 0,
    'File::chdir'              => 0,
    'File::Spec'               => 0,
    'YAML'                     => 0,
};

# test against ourself
my $mb = $class->new->dist_dir('t/old')->find_modules;
is( $mb->error, '' );
isa_ok( $mb, $class );

is_deeply( $mb->requires, $our_requires, "got our own requires" );

is_deeply(
    $mb->build_requires,
    { 'Test::More' => 0 },
    "got our own build_requires"
);

my $other = $class->new->dist_dir("t/mmish")->find_modules;

is_deeply(
    $other->requires,
    { 'Not::A::Real::Module' => 42 },
    "got other (makemaker) requires"
);

my $notthere = $class->new->dist_dir('t/no-such-dir')->find_modules;
like(
    $notthere->error,
    qr{^couldn't chdir to t/no-such-dir: },
    "fails on not existing dir"
);

$notthere->dist_dir('t/empty')->find_modules;
like(
    $notthere->error,
    qr{^No {Build,Makefile}.PL found },
    "fails on empty dir"
);

my $versioned = $class->new->dist_dir('t/build_version')->find_modules;
is_deeply(
    $versioned->requires,
    {   'Class::MethodMaker' => '1.02',
        'Term::ReadKey'      => '2.14'
    },
    "use Module::Build VERSION; no longer trips us up"
);

### gah, it seems File::chdir's localisation doesn't nest, otherwise we could use that here
chdir 't/old';
my $shy = Module::Depends->new->dist_dir('.')->find_modules;
chdir '../..';
is_deeply( $shy->requires, $our_requires,
    "got our own requires, non-intrusively" );

my $distant = Module::Depends->new->dist_dir('t/with-yaml')->find_modules;
is_deeply( $distant->requires, $our_requires,
    "got our own requires, non-intrusively, from a distance" );

my $inline_mm = $class->new->dist_dir('t/inline-makemaker')->find_modules;
is_deeply(
    $inline_mm->requires,
    {   'Inline::C'   => '0.44',
        'Time::Piece' => '1.08'
    },
    "use Inline::MakeMaker; no longer trips us up"
);

my $module_install = $class->new->dist_dir('t/module-install')->find_modules;
is( $module_install->error, '', "Module::Install no go boom" );
is_deeply(
    $module_install->build_requires,
    { 'Test::More' => '0.54' },
    "Module::Install build_requires"
);

is_deeply(
    $module_install->requires,
    { 'perl' => '5.5.3' },
    "Module::Install requires"
);

my $module_install_versioned = $class->new->dist_dir('t/module-install-versioned')->find_modules;
is_deeply(
    $module_install_versioned->configure_requires,
    { 'ExtUtils::Depends' => 0,
      'B::Hooks::OP::Check::EntersubForCV' => 0 },
    "Module::Install explicit version, configure_requires"
);


my $template_extract
    = $class->new->dist_dir('t/template-extract')->find_modules;
is_deeply(
    $template_extract->requires,
    {   'perl'     => '5.006',
        'Template' => 2
    },
    "Template::Extract Module::Install requires"
);

my $findbin = $class->new->dist_dir('t/uses-findbin')->find_modules;
is_deeply(
    $findbin->requires,
    { 'Not::A::Real::Module' => 42 },
    "odd outcome use of FindBin"
);

my $mm_false = $class->new->dist_dir('t/makemaker-false')->find_modules;
is( $mm_false->error, '',
    "Makefile.PL exiting false should not be considered an error",
);

