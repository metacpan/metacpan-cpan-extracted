use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my @pack = (["complex.pd", qw(Complex PDL::Complex), '', 1]);

my %hash = pdlpp_stdargs(@pack);
$hash{LIBS} = ['-lm'];
$hash{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'} = '7.14';
$hash{CONFIGURE_REQUIRES}{'PDL::Core::Dev'} = 0;
$hash{PREREQ_PM}{'PDL'} = '2.095';

sub MY::postamble { pdlpp_postamble(@pack); }

WriteMakefile(
  AUTHOR => 'Marc Lehmann <pcg@goof.com>',
  LICENSE => 'perl',
  MIN_PERL_VERSION => '5.016',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>'https://github.com/PDLPorters/PDL-Complex/issues'},
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Complex.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Complex',
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  %hash,
);
