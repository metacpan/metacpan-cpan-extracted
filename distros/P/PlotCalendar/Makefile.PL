# This -*- perl -*- script makes the Makefile

#--- Distribution section ---

$NAME     = 'PlotCalendar';
$DISTNAME = "PlotCalendar";
$VERSION  = "1.4";

BEGIN { require 5.001 }

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);

#--- Installation check

sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 $| = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0; 

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

#--- Write the Makefile

my @clean = qw(*% *.html *.b[ac]k *.old);

push @clean, map { "*/$_" } @clean;

WriteMakefile(
	VERSION   => $VERSION,
	DISTNAME  => $DISTNAME,
	NAME      => $NAME,
	PREREQ_PM => {'Time::DaysInMonth' => 1.0,
	              'Time::JulianDay' => 1.0,
			},
 
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
 
	'clean'   => {FILES => join(" ", @clean)},
);

