use strict;
use warnings;
use ExtUtils::MakeMaker;

# we create a Bad.pm whatever the value of
# PDLA_CONFIG - it's just the contents that will be
# different...

my $bvalflag = $PDLA::Config{WITH_BADVAL};
my $usenan = $PDLA::Config{BADVAL_USENAN};
my $bvalPerPdl = $PDLA::Config{BADVAL_PER_PDLA};

# print a banner to the screen
if ( $bvalflag ) {
    print "Congratulations - building PDLA with bad value support (WITH_BADVAL=1)\n\t";

    if ( $usenan ) {
 	print "+ using NaN for floating-point bad value";
    } else {
 	print "+ using -FLT_MAX/-DBL_MAX for floating-point bad values";
    }
    print "+ with per-piddle bad values (EXPERIMENTAL FEATURE)"
      if $bvalPerPdl;
} else {
    print "building PDLA without bad value support (WITH_BADVAL!=1)";
}
print "\n";

my @pack = (["bad.pd",qw(Bad PDLA::Bad)]);

my %hash = pdlpp_stdargs_int(@pack);

#$hash{LIBS} = ['-lm'];

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
	pdlpp_postamble_int(@pack);
};

WriteMakefile(%hash);
