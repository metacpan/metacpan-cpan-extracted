use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

WriteMakefile(
    NAME                => 'PDL::DSP::Fir',
    AUTHOR              => q{John Lapeyre <jlapeyre@cpan.org>},
    VERSION_FROM        => 'lib/PDL/DSP/Fir.pm',
    ABSTRACT_FROM       => 'lib/PDL/DSP/Fir.pm',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'PDL' => '2.105', # pdldoc_add
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
        'Test::PDL' => '0.22',
    },
    PREREQ_PM => {
        'PDL' => 0,
        'PDL::DSP::Windows' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDL-DSP-* ' },
    META_MERGE => {
      "meta-spec" => { version => 2 },
      resources => {
        bugtracker  => {web=>'https://github.com/jlapeyre/PDL-DSP-Fir/issues'},
        repository  => {
           url => 'git://github.com/jlapeyre/PDL-DSP-Fir.git',
           type => 'git',
           web => 'https://github.com/jlapeyre/PDL-DSP-Fir',
        },
        x_IRC => 'irc://irc.perl.org/#pdl',
      },
    },
);

sub MY::postamble { pdldoc_add() }

# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
  =head1 OVERVIEW

  Two modules for PDL providing some finite impulse response (FIR) filtering.

  =cut

EOF
$POD_header =~ s/^  //gm;

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open my $fh, '>', 'README.pod' or die "Couldn't open README.pod";
  print $fh $POD_header;

  foreach my $mod (qw(lib/PDL/DSP/Fir.pm lib/PDL/DSP/Fir/Simple.pm)) {
      open my $mod_fh, $mod or die "Couldn't open main module";
      while (<$mod_fh>)
      {
          if (/^=/../^=cut/)
          { print $fh $_; }
      }
  }
}
