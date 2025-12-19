use lib '.';
use inc::Module::Install;

RTx     'RT-Extension-AWS-Assets';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-aws-assets';

requires('Paws');

requires_rt '6.0.0';
rt_too_new '6.2.0';

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );
my $bin_path = $RT::BinPath || "$RT::BasePath/bin" || "/opt/rt6/bin";

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
           qw(bin/rt-import-aws-assets bin/rt-unlink-retired-reservations),
);

sign;
WriteAll;
