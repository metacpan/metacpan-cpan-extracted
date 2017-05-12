use warnings;
use strict;
use ExtUtils::MakeMaker::CPANfile;

use Config;
use File::Spec;
use constant WIN32 => $^O eq 'MSWin32';

my $home = $ENV{HOME};
my $has_myconfig = 0;
if ($home) {
  eval 
    {require File::Spec->catfile($home, '.cpan', 'CPAN', 'MyConfig.pm');};
  $has_myconfig = 1 unless $@;
}

unless ($has_myconfig) {
  eval {require CPAN::HandleConfig;};
  eval {require CPAN::Config;};
}

if ($@) {
  warn <<'WARN';
    
It appears you have yet to configure the CPAN.pm module.
PPM::Make would use this to map module to distribution names
in the event that a call to a remote soap server fails.
You can configure CPAN.pm by typing

    C:\> perl -MCPAN -e shell

and following through the dialogue.

WARN
}
my $sys_config = $INC{'CPAN/Config.pm'};
if (not $has_myconfig and not WIN32 and not -w $sys_config) {
  warn <<"WARN";

You do not have the right permissions to use the settings 
in $sys_config. I would suggest 
creating a CPAN::MyConfig module under $home,
in a .cpan/CPAN/ directory. See the CPAN.pm documentation
for details.

WARN
  exit;
}

my @exe_files = map{"bin/$_"} qw(make_ppm ppm_install rep_summary
                                 make_ppm_bundle make_ppm_install);

WriteMakefile(
  NAME         => 'PPM::Make',
  AUTHOR       => 'Randy Kobes <r.kobes@uwinnipeg.ca>',
  VERSION_FROM => 'lib/PPM/Make.pm',
  ABSTRACT_FROM => 'lib/PPM/Make.pm',
  EXE_FILES    => [@exe_files],
  LICENSE      => 'perl',
  dist         => {COMPRESS => 'gzip', SUFFIX => 'gz'},
  META_MERGE => {
    resources => {
      license => 'http://dev.perl.org/licenses/',
      homepage => 'https://github.com/charsbar/ppm-make',
      repository => 'https://github.com/charsbar/ppm-make',
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=PPM-Make',
      AnnoCPAN => 'http://annocpan.org/dist/PPM-Make',
      CPANForum => 'http://www.cpanforum.com/dist/PPM-Make',
      CPANTS => 'http://cpants.perl.org/dist/PPM-Make',
      Rating => 'http://cpanratings.perl.org/d/PPM-Make',
      SearchCPAN => 'http://search.cpan.org/~ISHIGAKI/PPM-Make/',
      Testers => 'http://cpantesters.perl.org/show/PPM-Make.html',
    },
  },
);
