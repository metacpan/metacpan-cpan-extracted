use inc::Module::Install;

RTx('RT-IODEF');
license('GPL Version 2');
author('Barely3am Solutions <wes@barely3am.com>');
version_from('lib/RT/IODEF.pm');

{ # check RT version
    my @v = split(/\./,"$RT::VERSION");
    if($v[0] <= 3){
        if($v[1] <= 8){
            if($v[2] < 10){
                die "RT-IODEF and newer needs RT 3.8.10 at least, you have $RT::VERSION";
            }
        }
    } else {
        warn "!!! WARNING: RT-IODEF hasn't been tested with RT4, use at your OWN RISK !!!";
        die 'remove line '.__LINE__.' in Makefile.PL to continue...';
    }
}

# XXX: This should be reported by M::I::RTx
my ($lib_path) = $INC{'RT.pm'} =~ /^(.*)[\\\/]/;
my $local_lib_path = "$RT::LocalPath/lib";
unshift @INC, $local_lib_path, $lib_path;

requires('XML::IODEF::Simple'   => '0.02');

auto_install();

tests("t/*.t t/*/*.t");

WriteAll();
