use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my $package = [ qw(VS.pd VS PDL::IO::HDF::VS) ];

undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble($package); };

my $pkg = ExtUtils::Depends->new(qw(PDL::IO::HDF::VS Alien::HDF4));
$pkg->set_inc(&PDL_INCLUDE());
$pkg->add_typemaps(&PDL_TYPEMAP());
$pkg->add_pm(
    'VS.pm' => '$(INST_LIBDIR)/VS.pm',
);

WriteMakefile(
    NAME => 'PDL::IO::HDF::VS',
    OBJECT => 'VS$(OBJ_EXT)',
    $pkg->get_makefile_vars,
    clean => {
        FILES => 'VS.pm VS.xs VS$(OBJ_EXT) VS.c',
    },
    dist => { 
        COMPRESS => 'gzip', 
        SUFFIX => 'gz', 
    },
    NO_MYMETA => 1,
);
