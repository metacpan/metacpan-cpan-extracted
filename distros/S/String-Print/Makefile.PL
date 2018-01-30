use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.93';

my %prereq  =
  ( Test::More        => 0.86
  , Unicode::GCString => 0
  , Encode            => 0
  , HTML::Entities    => 0
  , Date::Parse       => 2.30
  );

WriteMakefile
  ( NAME      => 'String::Print'
  , VERSION   => $version
  , PREREQ_PM => \%prereq

  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'printf extensions'
  , LICENSE   => 'perl'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
             { type => 'git'
             , url  => 'https://github.com/markov2/perl5-String-Print.git'
             , web  => 'https://github.com/markov2/perl5-String-Print'
             }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
  );

sub MY::postamble { <<'__POSTAMBLE' }

# for OODoc's oodist, DIST
RAWDIR          = ../public_html/string-print/raw
DISTDIR         = ../public_html/string-print/source
LICENSE         = perl

# for OODoc's oodist, POD
FIRST_YEAR      = 2016
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
EXTENDS         =

__POSTAMBLE
