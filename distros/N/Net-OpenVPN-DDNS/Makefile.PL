use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Net::OpenVPN::DDNS',
    'VERSION_FROM' => 'DDNS.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => '',
    'dist'      => {
        COMPRESS => 'gzip', SUFFIX => 'gz',
    },
    'INSTALLSCRIPT' => '/etc/openvpn/ddns',
    'INSTALLSITESCRIPT' => '/etc/openvpn/ddns',
    'INSTALLVENDORSCRIPT' => '/etc/openvpn/ddns',
    'EXE_FILES'     => [ 'update' ],
);
