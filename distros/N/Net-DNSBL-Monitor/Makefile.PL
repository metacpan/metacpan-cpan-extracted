use ExtUtils::MakeMaker;
use Config;

my $pkg = 'Net::DNSBL::Monitor';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> $pkg,
    'VERSION_FROM'	=> $module, # finds $VERSION
    'PREREQ_PM'		=> {
				Net::NBsocket		=> 0.14,
				Proc::PidUtil		=> 0.08,
				Net::DNS::Codes		=> 0.09,
				Net::DNS::ToolKit	=> 0.41,
				Net::DNSBL::MultiDaemon	=> 0.26,
				NetAddr::IP		=> 4.015,
				Test::More		=> 0,
			},
    'clean'		=> { FILES    => "*~ tmp*"},
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'}
);

sub MY::top_targets {
  package MY;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(pure_all\s+::.+)/$1 README/;
  $inherited;
}

sub MY::post_constants {
  my $post_constants = $Config{scriptdirexp} .'/pod2text';
  if (-e $post_constants) {
    $post_constants = q|
MY_POD2TEXT = |. $post_constants .q|
|;
  } else {   
    $post_constants = q|
MY_POD2TEXT = echo "perl distro missing 'pod2text' to convert " |;
  }
}

sub MY::postamble {
  package MY;
  my $postamble = q|
README  : |. $module .q|
	@$(MY_POD2TEXT) |. $module .q| > README

|;
}
