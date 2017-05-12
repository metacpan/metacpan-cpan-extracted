use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

my %prereq = (
				'YAML'				 				=> 0,
				'HTML::Mason'						=> 0,
				'Params::Validate'					=> 0,
				'Class::Container'					=> 0,
				'Mail::Sendmail'					=> 0,
				'Data::Dumper'						=> 0,
				'JSON::Any'							=> 0,
				'XML::Simple'						=> 0,
				'HTML::Template::Pro::Extension'	=> 0,
				'Time::HiRes'						=> 0,
				'HTML::Entities'					=> 0,
				'File::Spec'						=> 0,
				'DBIx::Class::Schema'				=> 0,
				'DBIx::Class::Schema::Loader'		=> 0,
				'Apache::DBI'						=> 0,
				'Scalar::Util'						=> 0,
				'Apache::Session::MySQL'			=> 0,
				'I18N::AcceptLanguage'				=> 0,
				'HTTP::BrowserDetect'				=> 0,
				'Text::CSV::Slurp'					=> 0,
				'Log::Any::Adapter'					=> 0,
				'mod_perl2' 						=> 1.999022,
);

my $mod_version;

eval { require Apache2::Cookie };
$mod_version = $@ ? undef : 2;
unless ($mod_version) {
	eval {require Apache::Cookie };
	$mod_version = $@ ? undef : 1;
}
unless ($mod_version) {
	warn 'Warning: prerequisite Apache::Cookie or Apache2::Cookie not found';
} else {
	$prereq{'Apache' . ($mod_version == 2 ? 2 : '') . '::Cookie'} = 0;
}




WriteMakefile(
    NAME              => 'Puzzle',
    VERSION_FROM      => 'lib/Puzzle.pm', # finds $VERSION
    PREREQ_PM         => \%prereq,
	LICENSE				=> 'gpl2',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Puzzle.pm', # retrieve abstract from module
       AUTHOR         => 'Emiliano Bruni <info@ebruni.it>') : ()),
);
