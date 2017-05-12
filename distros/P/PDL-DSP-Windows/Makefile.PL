use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# try again
# ignore following lines that say to ignore following paragraph
#
# Following paragraph is incorrect at the moment. Rather
# don't try to use CPAN, just point users to github.
#
# The file Windows.pm is generated at build time by mkwindows.not_a_perl_suffix. The
# only reason to include it in the distribution is so CPAN
# will use it for documentation rather than mkwindows.not_a_perl_suffix. I
# can't find a better way at the moment.
# See the bottom of this file Makefile.PL, where 
# lib/PDL/DSP/Windows.pm is deleted.

WriteMakefile(
    NAME                => 'PDL::DSP::Windows',
    AUTHOR              => q{John Lapeyre <jlapeyre@cpan.org>},
    VERSION_FROM        => 'lib/PDL/DSP/mkwindows.not_a_perl_suffix',
    ABSTRACT_FROM       => 'lib/PDL/DSP/mkwindows.not_a_perl_suffix',
    LICENSE=> 'perl',
    PL_FILES            => {},
    PM => {
        'lib/PDL/DSP/Windows.pm' => '$(INST_LIBDIR)/Windows.pm'
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDL-DSP-Windows-* lib/PDL/DSP/Windows.pm ' },
);

sub MY::postamble {
    '

lib/PDL/DSP/Windows.pm:
	cd lib/PDL/DSP && $(PERL) ./mkwindows.not_a_perl_suffix
'    
};
 
# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

A module for PDL providing window functions for signal processing.
Distributions of this module can be downloaded most easily from CPAN. 
(Commits tagged with version numbers, may also be downloaded from
 github.)

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open MOD, 'lib/PDL/DSP/Windows.pm' or die "Couldn't open main module Windows.pm";
  open README, '>README.pod'              or die "Couldn't open README.pod";

  print README $POD_header;

  while (<MOD>)
  {
    if (/^=/../^=cut/)
    { print README; }
  }
}

# delete lib/PDL/DSP/Windows.pm so we are sure it will
# be regenerated.

unlink 'lib/PDL/DSP/Windows.pm';
