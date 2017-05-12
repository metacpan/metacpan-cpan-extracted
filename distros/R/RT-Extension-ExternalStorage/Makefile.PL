use inc::Module::Install;

RTx('RT-Extension-ExternalStorage');

requires( 'File::Spec' );
requires( 'File::Path' );

requires_rt '4.0.22';

recommends 'Amazon::S3';
recommends 'File::Dropbox';

no_index( package => 'RT::Record', 'RT::ObjectCustomFieldValue', 'RT::Attachment');

auto_install;

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
    'sbin/extract-attachments',
    'lib/RT/Extension/ExternalStorage/Test.pm',
);

sign;
WriteAll;
