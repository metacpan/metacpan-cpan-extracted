use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-AutomaticAssignment';

requires 'Business::Hours';

requires_rt '5.0';
rt_too_new '5.2';

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";

# Straight from perldoc perlvar
use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS') {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

substitute(
    {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
        PERL        => $ENV{PERL} || $secure_perl_path,
    },
    { sufix => '.in'},
    'lib/RT/Extension/AutomaticAssignment/Test.pm',
);

sign;
WriteAll;
