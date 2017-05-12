# This -*-perl-*- script writes the Makefile for installing this distribution.
# ( Last Modified Time-stamp: "2014-07-26 02:34:05 MDT sburke@cpan.org" )
#======================================================================
#
# For info on instaling this module and how to control it, see:
#   perldoc cpan
#   perldoc cpanp
#   perldoc perlmodinstall
#   perldoc ExtUtils::MakeMaker
#
#
#======================================================================

require                   5.008_000;  #   # <==========!!!!!!!!!!
my $min_perl_version =    5.008_000;  #   # <==========!!!!!!!!!!

# For the module author: see lib/ExtUtils/MakeMaker.pm for details
#   of how to influence the contents of the Makefile that is written.
# Incidentally. Perldoc perlfunc says "use " is compile-time, but
#   "require 5.6" is runtime.

use ExtUtils::MakeMaker;
#if( $ExtUtils::MakeMaker::VERSION < 6.47 ) {
#  die "I need at least perl version $min_perl_version";
#}

WriteMakefile(
  'NAME'	        => 'PerlIO::via::Unidecode',
  'VERSION_FROM'  => 'lib/PerlIO/via/Unidecode.pm',
  'ABSTRACT_FROM' => 'lib/PerlIO/via/Unidecode.pm',
  'PREREQ_PM' => {
      'strict'  => 0,
      'utf8'   => 0,
      'Text::Unidecode' => 0,
  },

  'AUTHOR'       => 'Sean Burke <sburke@cpan.org>',
  'LICENSE'      => 'perl',
                   #  "...under the same terms as Perl itself"


  ($ExtUtils::MakeMaker::VERSION >= 6.47
    ? ('MIN_PERL_VERSION' => $min_perl_version )

    : () # Otherwise we can't express that metadata about this
         #  whole module suite, and we just have to let the version
         #  "require" thing up there block this whole Makefile.PL
         #  from running.
  ),

  'dist'        => { COMPRESS => 'gzip -4f', SUFFIX => 'gz', },
    
);

__END__
