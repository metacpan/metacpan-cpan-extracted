use 5.008001;
use ExtUtils::MakeMaker;
use warnings; use strict;

use lib qw(inc);
use Devel::CheckLib;

# No support for Win32 yet
die "OS unsupported\n" if $^O eq 'MSWin32';

use Config;
use File::Spec::Functions qw( catfile );
use Getopt::Long;

my %argv;
GetOptions(
    \%argv,
    'sharktools-src=s',
    'wireshark-src=s',
    'lib-path=s@',
    'inc-path=s@',
);

unless ( defined $argv{'sharktools-src'} ) {
    $argv{'sharktools-src'} = catfile(
        $ENV{HOME}, qw(shark sharktools-0.1.5 src) );
}

unless ( defined $argv{'wireshark-src'} ) {
    $argv{'wireshark-src'} = catfile(
        $ENV{HOME}, qw(shark wireshark-1.4.3) );
}

unless ( defined $argv{'lib-path'} ) {
    $argv{'lib-path'} = [ split(' ', $Config{libpth}) ];
}

unless ( defined $argv{'inc-path'} ) {
    $argv{'inc-path'} = [qw(
        /usr/include/glib-2.0
        /usr/lib/glib-2.0/include
    )];
}

check_all_libs_or_exit(\%argv);

my $LIBS = join ' ', (
    (map "-L$_", $argv{'sharktools-src'}, @{ $argv{'lib-path'} }),
    (map "-l$_", qw(sharktools glib-2.0 wireshark wiretap wsutil)),
);

my $INC = join ' ', (map "-I$_", 
    @{ $argv{'inc-path'} }, 
    $argv{'wireshark-src'},
    catfile($argv{'wireshark-src'}, 'wiretap'),
    $argv{'sharktools-src'},
);

WriteMakefile(
    NAME              => 'Net::Sharktools',
    VERSION_FROM      => 'lib/Net/Sharktools.pm',
    LICENSE           => 'gpl2',

    BUILD_REQUIRES    => {
        'Config'                => 0,
        'File::Spec::Functions' => 0,
        'Getopt::Long'          => 0,
        'YAML'                  => 0,
    },

    PREREQ_PM         => {},
    MIN_PERL_VERSION => '5.008001',

    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/Net/Sharktools.pm', 
       AUTHOR         => 'A. Sinan Unur <nanis@cpan.org>') : ()),
    
    LIBS              => [ $LIBS ],
    
    CCFLAGS           => '-Wall -Werror',
    DEFINE            => '', 
    
    INC               => $INC,
);

sub check_all_libs_or_exit {
    my ($argv) = @_;

    my $sharktools_src = $argv->{'sharktools-src'};
    my $wireshark_src  = $argv->{'wireshark-src'};
    my @inc = @{ $argv->{'inc-path'} };
    my @lib = @{ $argv->{'lib-path'} };

    check_lib_or_exit(
        function => qq{
            #include <string.h>
            return strcmp(PACKAGE, "wireshark");
        },
        header => [qw( config.h )],
        incpath => $wireshark_src, 
    );

    check_lib_or_exit(
        header => 'sharktools_core.h',
        incpath => [
            $sharktools_src,
            $wireshark_src,
            @inc,
        ],
    );

    check_lib_or_exit(
        lib => 'sharktools',
        libpath => $sharktools_src,
    );

    for my $lib ( qw(glib-2.0 wireshark wiretap wsutil) ) {
        check_lib_or_exit(
            lib => $lib,
            libpath => \@lib,
        );
    }
}

