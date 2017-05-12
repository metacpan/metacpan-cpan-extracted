use inc::Module::Install;
RTx('RT-Condition-Complex');
all_from 'lib/RT/Condition/Complex.pm';
readme_from 'lib/RT/Condition/Complex.pm';

requires('Parse::BooleanLogic');
requires('Regexp::Common');

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    'lib/RT/Condition/Complex/Test.pm',
);

WriteAll();
