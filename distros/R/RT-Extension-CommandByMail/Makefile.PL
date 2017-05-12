use inc::Module::Install;

RTx ('RT-Extension-CommandByMail');
no_index package => "RT::Extension::CommandByMail::Test";
build_requires('Test::More');
build_requires('IPC::Open2');

repository('https://github.com/bestpractical/rt-extension-commandbymail');

auto_install();

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
my $sbin_path = $RT::SbinPath || "$RT::BasePath/sbin" || "/opt/rt3/sbin";
my $bin_path = $RT::BinPath || "$RT::BasePath/bin" || "/opt/rt3/bin";

substitute(
    {
        RT_LIB_PATH  => $lib_path,
        RT_BIN_PATH  => $bin_path,
        RT_SBIN_PATH => $sbin_path,
    },
    {
        sufix => '.in'
    },
    qw(lib/RT/Extension/CommandByMail/Test.pm),
);

no_index package => 'RT::Extension::CommandByMail::Test';

author_tests('xt');

sign;
WriteAll();
