use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $package = [ qw(SD.pd SD PDLA::IO::HDF::SD) ];

my $pkg = eval { ExtUtils::Depends->new(qw(PDLA::IO::HDF::SD Alien::HDF4)) };
if (!$pkg) {
    write_dummy_make( $msg );
    return;
}

$pkg->set_inc(&PDLA_INCLUDE());
$pkg->add_typemaps(&PDLA_TYPEMAP());
$pkg->add_pm(
    'SD.pm' => '$(INST_LIBDIR)/SD.pm',
);

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble($package); };

WriteMakefile(
    NAME => 'PDLA::IO::HDF::SD',
    OBJECT => 'SD.o ',
    $pkg->get_makefile_vars,
    clean => {
        FILES => 'SD.pm SD.xs SD.o SD.c',
    },
    dist => { 
        COMPRESS => 'gzip', 
        SUFFIX => 'gz'
    }, 
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
