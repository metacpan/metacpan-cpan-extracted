use inc::Module::Install;
use utf8;

RTx 'RT-Extension-BooleanCustomField';
license 'gplv3';
repository 'https://github.com/gibus/RT-Extension-BooleanCustomField';

requires_rt('4.0.0');
rt_too_new('4.6.0');

readme_from 'lib/RT/Extension/BooleanCustomField.pm', 0, 'md', 'README.md';

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
           qw(lib/RT/Extension/BooleanCustomField/Test.pm),
);

auto_install;
sign;
WriteAll;
