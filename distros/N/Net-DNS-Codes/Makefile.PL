use ExtUtils::MakeMaker;

use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> "Net::DNS::Codes",
    'VERSION_FROM'	=> "Codes.pm", # finds $VERSION
    'dist'		=> {COMPRESS=>'gzip', SUFFIX=>'gz'},
    'clean'		=> { FILES    => "*~ tmp*"}
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
README  : Codes.pm
	@$(MY_POD2TEXT) Codes.pm > README

|;
}
