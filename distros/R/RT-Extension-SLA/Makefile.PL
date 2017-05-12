use inc::Module::Install;

RTx ('RT-Extension-SLA');
repository('https://github.com/bestpractical/rt-extension-sla');

requires_rt '4.0.0';
rt_too_new '4.4.0';

build_requires('Test::More');

requires('Business::Hours');
auto_install();

no_index package => 'RT::Queue';

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
        sufix => '.in',
    },
    qw(lib/RT/Extension/SLA/Test.pm),
);

sign;
WriteAll();
