#!perl -T
use strict;
use File::Spec::Functions;
use Test::More;
use Module::ThirdParty;


plan skip_all => "will currently fail because of RTx-Shredder"
    unless -d "releases";

my $cpan = undef;

# check that we have the necessary prerequisites to run this test
for my $prereq (qw(Module::CoreList Parse::CPAN::Packages File::HomeDir)) {
    plan skip_all => "$prereq not available"  unless eval "use $prereq; 1";
}

# all modules known by Module::ThirdParty
my @modules = Module::ThirdParty::all_modules();

# find a 02packages file
my $home_dir = File::HomeDir->my_home;
for my $path ( catdir(qw(.cpan sources modules)), ".cpanplus" ) {
    my $filepath = catfile($home_dir, $path, "02packages.details.txt.gz");
    next unless -f $filepath;
    local $^W = 0;  # Parse::CPAN::Packages warns like hell
    $cpan = Parse::CPAN::Packages->new($filepath);
    last if $cpan;
}

plan skip_all => "can't find 02packages.details.txt.gz" unless $cpan;

plan tests => @modules * 4;

for my $module (@modules) {
    my $is_core = eval { Module::CoreList->first_release($module) };
    is( $@, "", "Module::CoreList->first_release($module)" );
    ok( !$is_core, "check that the module '$module' isn't core" );

    my $info = eval { $cpan->package($module) };
    is( $@, "", "Parse::CPAN::Packages->package($module)" );
    ok( !$info, "check that the module '$module' isn't indexed on the CPAN" );
}

