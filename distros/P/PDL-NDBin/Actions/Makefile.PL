use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $package = [ "actions.pd", 'Actions_PP', 'PDL::NDBin::Actions_PP', undef, 1 ];
my %args = (
	pdlpp_stdargs( $package ),
);
undef &MY::postamble; *MY::postamble = sub { pdlpp_postamble( $package ) };
WriteMakefile( %args );
