use inc::Module::Install;

RTx 'RT-Extension-AssetSQL';

no_index package => "RT::Assets";

requires_rt '4.4';
rt_too_new '4.6';

perl_version '5.010001';

repository('https://github.com/bestpractical/rt-extension-assetsql');

my ($loaded) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $loaded );

substitute(
    {
        RT_LIB_PATH  => $lib_path,
    },
    {
        sufix => '.in'
    },
    q(xt/lib/RT/Extension/AssetSQL/Test.pm),
);

WriteAll;
