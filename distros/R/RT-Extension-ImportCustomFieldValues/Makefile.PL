use inc::Module::Install;

RTx 'RT-Extension-ImportCustomFieldValues';
license 'gpl_3';
repository 'http://git.home-dn.net/?p=manu/RT-Extension-ImportCustomFieldValues';

requires('Text::CSV');
requires_rt('4.2.0');
rt_too_new('6.1.0');

readme_from 'lib/RT/Extension/ImportCustomFieldValues.pm', 0;

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
my $bin_path = $RT::BinPath || "$RT::BasePath/bin" || "/opt/rt4/bin";

# Straight from perldoc perlvar
use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

substitute(
    {
        RT_LIB_PATH  => $lib_path,
        RT_BIN_PATH  => $bin_path,
        PERL         => $ENV{PERL} || $secure_perl_path,
    },
           {
        sufix => '.in'
    },
           qw(lib/RT/Extension/ImportCustomFieldValues/Test.pm),
);

auto_install;
sign;
WriteAll;
