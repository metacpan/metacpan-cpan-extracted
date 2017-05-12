use inc::Module::Install;
RTx('RT-Extension-ColumnMap');
all_from 'lib/RT/Extension/ColumnMap.pm';
readme_from 'lib/RT/Extension/ColumnMap.pm';

requires('Regexp::Common::delimited');
requires('Regexp::Common::WithActions');

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    'lib/RT/Extension/ColumnMap/Test.pm',
);

WriteAll();
