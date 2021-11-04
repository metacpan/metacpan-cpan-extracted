use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PDL::DSP::Fir',
    AUTHOR              => q{John Lapeyre <jlapeyre@cpan.org>},
    VERSION_FROM        => 'lib/PDL/DSP/Fir.pm',
    ABSTRACT_FROM       => 'lib/PDL/DSP/Fir.pm',
    LICENSE => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL' => 0,
        'PDL::DSP::Windows' => 0
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


# reroute the main POD into a separate README.pod if requested. This is here
# purely to generate a README.pod for the github front page
my $POD_header = <<EOF;
=head1 OVERVIEW

Two modules for PDL providing some fir filtering. These modules
are on CPAN

=cut

EOF

if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  open README, '>README.pod'              or die "Couldn't open README.pod";
  print README $POD_header;

  foreach my $mod  ('lib/PDL/DSP/Fir.pm', 'lib/PDL/DSP/Fir/Simple.pm') {
      open MOD, $mod or die "Couldn't open main module";
      while (<MOD>)
      {
          if (/^=/../^=cut/)
          { print README; }
      }
      close(MOD);
  }
  close(README);
}
