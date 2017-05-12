use ExtUtils::MakeMaker;
use Config;

my $pkg = 'Net::NBsocket';
$pkg =~ /[^:]+$/;
my $module = $& .'.pm';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> $pkg,
    'VERSION_FROM'	=> $module, # finds $VERSION
    'PREREQ_PM'		=> {
			NetAddr::IP		=> 4.049
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
