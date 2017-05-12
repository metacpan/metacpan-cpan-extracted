require 5.006;

use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if($MM_Version =~ /_/) # dev version
{
  $MM_Version = eval $MM_Version;
  die $@  if($@);
}

WriteMakefile(NAME         => 'Rose::URI',
              PMLIBDIRS    => [ 'lib' ],
              VERSION_FROM => 'lib/Rose/URI.pm',
              ($^O =~ /darwin/i ?
               (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                Rose::Object => '0.015',
                overload     => 0,
                URI          => 0,
                URI::Escape  => 0,
              },
              ($MM_Version >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
              ($MM_Version >= 6.31 ? (LICENSE => 'perl') : ()),
              ($MM_Version <= 6.44 ? () : 
              (META_MERGE => 
              {
                resources =>
                {
                  license     => 'http://dev.perl.org/licenses/',
                  bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-URI',
                  repository  => 'http://rose.googlecode.com/svn/trunk/modules/Rose-URI',
                },
              })));
