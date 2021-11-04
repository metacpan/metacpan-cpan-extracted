#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/TableData/Perl/CPAN/Release/Static/1995.pm','lib/TableData/Perl/CPAN/Release/Static/1996.pm','lib/TableData/Perl/CPAN/Release/Static/1997.pm','lib/TableData/Perl/CPAN/Release/Static/1998.pm','lib/TableData/Perl/CPAN/Release/Static/1999.pm','lib/TableData/Perl/CPAN/Release/Static/2000.pm','lib/TableData/Perl/CPAN/Release/Static/2001.pm','lib/TableData/Perl/CPAN/Release/Static/2002.pm','lib/TableData/Perl/CPAN/Release/Static/2003.pm','lib/TableData/Perl/CPAN/Release/Static/2004.pm','lib/TableData/Perl/CPAN/Release/Static/2005.pm','lib/TableData/Perl/CPAN/Release/Static/2006.pm','lib/TableData/Perl/CPAN/Release/Static/2007.pm','lib/TableData/Perl/CPAN/Release/Static/2008.pm','lib/TableData/Perl/CPAN/Release/Static/2009.pm','lib/TableData/Perl/CPAN/Release/Static/2010.pm','lib/TableData/Perl/CPAN/Release/Static/2011.pm','lib/TableData/Perl/CPAN/Release/Static/2012.pm','lib/TableData/Perl/CPAN/Release/Static/2013.pm','lib/TableData/Perl/CPAN/Release/Static/2014.pm','lib/TableData/Perl/CPAN/Release/Static/2015.pm','lib/TableData/Perl/CPAN/Release/Static/2016.pm','lib/TableData/Perl/CPAN/Release/Static/2017.pm','lib/TableData/Perl/CPAN/Release/Static/2018.pm','lib/TableData/Perl/CPAN/Release/Static/2019.pm','lib/TableData/Perl/CPAN/Release/Static/2020.pm','lib/TableDataBundle/Perl/CPAN/Release/Static/Older.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
