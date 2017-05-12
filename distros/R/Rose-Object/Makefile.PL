require 5.006;

use ExtUtils::MakeMaker;

eval { require Rose::DateTime::Util };

if($@)
{
  warn<<"EOF";

##
## WARNING: You are missing Rose::DateTime
##
## There is a circular dependency between Rose::Object and Rose::DateTime.
## Rose::Object will simply skip all tests that require Rose::DateTime, but
## you should really re-run "make test" after installing Rose::DateTime
## just to make sure everything works correctly.
##

EOF
}

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if($MM_Version =~ /_/) # dev version
{
  $MM_Version = eval $MM_Version;
  die $@  if($@);
}

WriteMakefile(NAME          => 'Rose::Object',
              ABSTRACT_FROM => 'lib/Rose/Object.pm',
              VERSION_FROM  => 'lib/Rose/Object.pm',
              ($^O =~ /darwin/i ? (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                # This is a circular dependency...
                #Rose::DateTime => 0,
                Test::Simple => 0,
                Test::More   => 0,
              },
              AUTHOR => 'John Siracusa <siracusa@gmail.com>',
              ($MM_Version >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
              ($MM_Version >= 6.31 ? (LICENSE => 'perl') : ()),
              ($MM_Version <= 6.44 ? () : 
              (META_MERGE => 
              {
                resources =>
                {
                  license     => 'http://dev.perl.org/licenses/',
                  homepage    => 'http://rose.googlecode.com/',
                  bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-Object',
                  repository  => 'http://rose.googlecode.com/svn/trunk/modules/Rose-Object',
                },
              })));


