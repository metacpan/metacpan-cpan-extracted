use strict;

use ExtUtils::MakeMaker;

# this ugliness comes from incompatibility of certain versions of
# Test::Tester with certain version of Test::Builder. The problem is
# that people might have an old TT lying around and are also likely to
# have quite a new TB. This detects that situation and hopefully
# demands an install of a newer TT.

my $tt_prereq = "0.04";

if (eval { require Test::Tester; require Test::Builder; 1 } &&
  $Test::Tester::VERSION <= 0.106 &&
  $Test::Builder::VERSION >= 0.78) {

  $tt_prereq = "0.107";
}

my $mm_ver = ExtUtils::MakeMaker->VERSION;

my %t_prereq = (
  'Test::More'       => '0.88',
  'Test::Tester'     => $tt_prereq,
);

my %prereq = (
  'Test::Builder'    => '0',
  'Scalar::Util'     => '1.09',

  # apparently CPAN doesn't get the version of Scalar::Util
  'List::Util'       => '1.09',

  ($mm_ver < 6.55_01 ? %t_prereq : ()),
);

my %extra_meta  = $mm_ver >= 6.55_01
                ? $mm_ver >= 6.63_03 ? (TEST_REQUIRES  => \%t_prereq)
                                     : (BUILD_REQUIRES => \%t_prereq)
                : ();

WriteMakefile(
  AUTHOR       => 'Fergal Daly <fergal@esatclear.ie>',
  NAME         => 'Test::Deep',
  VERSION_FROM => './lib/Test/Deep.pm',
  PREREQ_PM    => \%prereq,
  %extra_meta,

  LICENSE => "perl",

  # This is a dumb mistake.  Why did it get done?  I'm the one who did it and I
  # don't know.  It only affects perl 5.8, and stopping doing it now would be a
  # problem, because upgrades wouldn't actually upgrade.  I'll just leave it
  # here until 5.8 is really and truly dead enough. -- rjbs, 2013-11-30
  ($] < 5.010 ? (INSTALLDIRS => 'perl') : ()),

  ($mm_ver < 6.46 ? () : (META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 1,
    resources       => {
      homepage      => 'http://github.com/rjbs/Test-Deep/',
      repository    => {
         url        => 'https://github.com/rjbs/Test-Deep.git',
         web        => 'https://github.com/rjbs/Test-Deep',
         type       => 'git',
      },
      bugtracker    => {
         web        => 'http://github.com/rjbs/Test-Deep/issues',
      },
      x_MailingList => 'http://lists.perl.org/list/perl-qa.html',
      x_IRC         => 'irc://irc.perl.org/#perl-qa',
    },
  })),

);
