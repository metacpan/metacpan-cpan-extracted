use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $package = [ "utils.pd", 'Utils_PP', 'PDL::NDBin::Utils_PP' ];
my %args = (
	pdlpp_stdargs( $package ),
	VERSION => '0.019',
);
WriteMakefile( %args );
sub MY::postamble { pdlpp_postamble( $package ) }
