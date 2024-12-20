use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

require "./pdlmaker.plm";

my $package = [qw(EditDistance.pd EditDistance PDL::EditDistance)];
my %hash = pdlmaker_init($package);

##-- preqrequistes (for PREREQ_PM)
my %prereq = (
	      'PDL' => 0, #'2.4.2',
	      'ExtUtils::MakeMaker' => 0,
	      'Test::More' => 0,
	     );

$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'Compute Wagner-Fischer edit distance and alignment matrices on PDLs';
$hash{PREREQ_PM} = {%prereq};
$hash{CONFIGURE_REQUIRES} = {%prereq};
push(@{$hash{LIBS}}, '-lm');
#$hash{INC} .= '';
$hash{DIR} = [];
#$hash{OBJECT} .= '';
$hash{VERSION_FROM} = 'EditDistance.pd';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt';

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
