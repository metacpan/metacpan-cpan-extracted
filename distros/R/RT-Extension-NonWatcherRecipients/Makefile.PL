use inc::Module::Install;

RTx 'RT-Extension-NonWatcherRecipients';
license  'gplv2';

repository 'https://github.com/bestpractical/rt-extension-nonwatcherrecipients';

my ($lp) = ($INC{'RT.pm'} =~ /^(.*)[\\\/]/);
my $lib_path = join( ' ', "$RT::LocalPath/lib", $lp );

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
        PERL         => $ENV{PERL} || $secure_perl_path,
    },
           {
        sufix => '.in'
    },
           qw(lib/RT/Extension/NonWatcherRecipients/Test.pm),
);

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;
