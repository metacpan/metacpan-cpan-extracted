# Makefile.PL for a package defined by PP code.

use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;

$package = ["wgrib.pd",Wgrib,PDL::IO::Grib::Wgrib];

%hash = pdlpp_stdargs($package);
$hash{OBJECT} .= ' BDSunpk$(OBJ_EXT) flt2ibm$(OBJ_EXT)';
$hash{clean}->{FILES} .= ' BDSunpk$(OBJ_EXT) flt2ibm$(OBJ_EXT)';
$hash{'VERSION_FROM'} = '../Grib.pm';
$hash{PM}->{'Field.pm'} = '$(INST_LIBDIR)/Field.pm';
$hash{PM}->{'Gribtables.pm'} = '$(INST_LIBDIR)/Gribtables.pm';
#$hash{LIBS} = '-lm';

#use Data::Dumper;
#my $out = Dumper(\%hash);
#print $out;

WriteMakefile(%hash);
sub MY::postamble { pdlpp_postamble($package); }
