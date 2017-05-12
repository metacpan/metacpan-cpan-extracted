#
# Makefile.PL for Penguin Greetings modules
# E. Lagache, 4/2005
#

sub optional_modules {
#
# Subroutine to print out consistent warnings for modules that are used
# in some of the Penguin Greetings secondary ecard sites but
# aren't needed for an initial installation.
#
  my $module_list_ref = shift;
  my @missing_modules = ();

  foreach my $module (@{$module_list_ref}) {
	eval "require $module";

	if ($@) {
	  push @missing_modules, $module;
	}
  }

  if (@missing_modules) {
	print "Note: Modules @missing_modules were not found.\n\n";

	print "While not needed to run Penguin Greetings, these module(s) are\n",
          "used by some of the secondary ecard sites and provide additional\n",
          "functionality.  Tests related to these module(s) will be ",
          "disabled\n\n";
  sleep 2;
  }
}

# Definitions
$DISTNAME = 'Pgreet';
$VERSION  = "1.0.0";

# Prerequisites
BEGIN { require 5.8.0 }
use ExtUtils::MakeMaker;

# Check on optional modules
my @optional_modules = ('HTML::Mason', 'Locale::Maketext');

optional_modules(\@optional_modules);


#--- Write the Makefile
WriteMakefile( # Prerequisites same as for Install.PL
			  PREREQ_PM => {
							'MIME::Lite' => '2.117',
							'Apache::Htpasswd' => '1.5.5',
							'Date::Pcalc' => '1.2',
							'Config::General' => '2.19',
							'String::Checker' => '0.03',
							'Digest::MD5' => '2.17',
							'Log::Dispatch' => '2.06',
							'Embperl' => '2.0',
							'I18N::AcceptLanguage' => '1.00'
						   },
			  VERSION   => $VERSION,
			  NAME      => $DISTNAME,	
			  ($] >= 5.005) ? (
							   'AUTHOR'     =>
							   'Edouard Lagache (elagache@canebas.org)',
							   'ABSTRACT'   =>
							   'Support modules for Penguin Greetings'
							  ) : (),
			 );


