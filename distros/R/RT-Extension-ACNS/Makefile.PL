use inc::Module::Install;

RTx 'RT-Extension-ACNS';

repository 'https://github.com/bestpractical/rt-extension-acns' ;

requires 'Parse::ACNS';

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    'lib/RT/Extension/ACNS/Test.pm',
);

sign();
WriteAll();
