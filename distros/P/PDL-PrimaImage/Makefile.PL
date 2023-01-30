use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;
use Prima::Config;

my @pack = qw(primaimage.pd PrimaImage PDL::PrimaImage);
my %hash = pdlpp_stdargs(\@pack);
$hash{INC} .= " $Prima::Config::Config{inc}";
push @{$hash{LIBS}}, $Prima::Config::Config{libs};
$hash{DEFINE} .= " $Prima::Config::Config{define}";
$hash{META_MERGE}{resources}{repository} = 'https://github.com/dk/PDL-PrimaImage';
$hash{CONFIGURE_REQUIRES} = {
  'ExtUtils::MakeMaker' => '7.14',
  'PDL' => '2.075',
  'Prima' => '1.67',
};
$hash{PREREQ_PM} = {
  'PDL' => '2.075',
  'Prima' => '1.67',
};

WriteMakefile(%hash);
sub MY::postamble { pdlpp_postamble(\@pack); }
