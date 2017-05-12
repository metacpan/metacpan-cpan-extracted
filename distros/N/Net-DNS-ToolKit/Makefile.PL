use ExtUtils::MakeMaker;
use Config;
use Cwd;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if ($Config{osname} =~ /Win/) {
    warn "Windows not supported, porters welcome!\n";
    exit 0;
}

WriteMakefile(
    'NAME'		=> 'Net::DNS::ToolKit',
    'VERSION_FROM'	=> 'ToolKit.pm', # finds $VERSION
    'PREREQ_PM'		=> {	Net::DNS::Codes	=> 0.09,
				NetAddr::IP::Util => 1.30
			},
    'LIBS'		=> ['-lresolv'], # e.g., '-lm'
    'depend'		=> {'ToolKit.c'	=> 'ToolKit.h xs_include/dn_expand.inc',
			},
    'clean'		=> { FILES	=> "*.bs *.o *~ localStuff.h config.log"},
);

sub MY::top_targets {
  package MY;
  my $begin = q|
config  :: localStuff.h
	@$(NOOP)

# siteconf CCname Cfile_ext OBJext EXEext "Cflags" "LDflags" "LDLOADLIBS"
#
localStuff.h :
	$(SHELL) siteconf "$(CC)" ".c" "$(OBJ_EXT)" "$(EXE_EXT)" "$(CCFLAGS)" "$(LDFLAGS)" "$(LDLOADLIBS)"
|;
  my $inherited = shift->SUPER::top_targets(@_);
  $inherited =~ s/(pure_all\s+::.+)/$1 README/;
  $begin . $inherited;
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
README  : ToolKit.pm
	@$(MY_POD2TEXT) ToolKit.pm > README

|;
}
