use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $package = [ "utils.pd", 'Utils_PP', 'PDL::NDBin::Utils_PP', undef, 1 ];
my %args = (
	pdlpp_stdargs( $package ),
);
undef &MY::postamble; *MY::postamble = sub { pdlpp_postamble( $package ) };
WriteMakefile( %args );
