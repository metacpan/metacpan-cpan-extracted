use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $package = [ qw(SD.pd SD PDL::IO::HDF::SD) ];
my $pkg = ExtUtils::Depends->new(qw(PDL::IO::HDF::SD Alien::HDF4));
$pkg->set_inc(&PDL_INCLUDE());
$pkg->add_typemaps(&PDL_TYPEMAP());
$pkg->add_pm(
    'SD.pm' => '$(INST_LIBDIR)/SD.pm',
);

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble($package); };

WriteMakefile(
    NAME => 'PDL::IO::HDF::SD',
    OBJECT => 'SD$(OBJ_EXT) ',
    $pkg->get_makefile_vars,
    clean => {
        FILES => 'SD.pm SD.xs SD$(OBJ_EXT) SD.c',
    },
    dist => { 
        COMPRESS => 'gzip', 
        SUFFIX => 'gz'
    }, 
    NO_MYMETA => 1,
);
