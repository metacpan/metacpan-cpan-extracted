use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

require "./pdlmaker.plm";

$package  = ["HMM.pd",HMM,PDL::HMM];
%hash = pdlmaker_init($package);

my %prereq = (
              PDL => '2.081',
              'Test::More'=>0,
             );

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'PDL Hidden Markov Model utilities';
$hash{PREREQ_PM} = {%prereq};
$hash{CONFIGURE_REQUIRES} = {%prereq,'ExtUtils::MakeMaker'=>0};
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
##
$hash{VERSION_FROM} = 'HMM.pd';
##
$hash{realclean}{FILES} .= ' *~ *.tmp README.txt';

my $package_name = $package->[2];
(my $repo = $package_name) =~ s#::#-#g;
$repo = "moocow-the-bovine/$repo";
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    homepage => 'http://pdl.perl.org/',
    bugtracker  => {web=>"https://github.com/$repo/issues"},
    repository  => {
      url => "git://github.com/$repo.git",
      type => 'git',
      web => "https://github.com/$repo",
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
};

WriteMakefile(%hash);
