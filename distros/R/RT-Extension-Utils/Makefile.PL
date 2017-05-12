use inc::Module::Install;
RTx('RT-Extension-Utils');
all_from 'lib/RT/Extension/Utils.pm';
readme_from 'lib/RT/Extension/Utils.pm';

my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

my @tools;
use File::Find ();
File::Find::find(
    {
        no_chdir => 1,
        wanted => sub { -f $File::Find::name && push @tools, $File::Find::name },
    },
    'bin', 'sbin'
);

substitute( {
        RT_LIB_PATH => join( ' ', $local_lib_path, $lib_path ),
    },
    @tools
) if @tools;

# default set of modules
requires  'Data::Dumper';
requires  'File::Spec';
requires  'Getopt::Long';

WriteAll();
