require 5.006;

use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if($MM_Version =~ /_/) # dev version
{
  $MM_Version = eval $MM_Version;
  die $@  if($@);
}

eval { require DateTime };

unless($@)
{
  if($DateTime::VERSION < 0.20)
  {
    warn<<"EOF";

##
## *** WARNING: Ancient version of DateTime detected ***
##
## You appear to have DateTime version $DateTime::VERSION installed.  This
## is very old.  You should have DateTime version 0.20 at least.  Some
## tests may fail unless you upgrade DateTime.  The latest stable version
## is recommended.
##
##

EOF
  }
}

WriteMakefile(NAME         => 'Rose::HTML::Objects',
              VERSION_FROM => 'lib/Rose/HTML/Objects.pm',
              ($^O =~ /darwin/i ? (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                'base'            => '2.18',
                'Scalar::Util'    => 0,
                'DateTime'        => '0.20',
                'Carp'            => 0,
                'Clone::PP'       => 0,
                'Encode'          => 0,
                'Email::Valid'    => 0,
                'HTML::Entities'  => 0,
                'Image::Size'     => 0,
                'List::Util'      => '1.45',
                'URI::Escape'     => 0,
                'File::Spec'      => 0,
                'File::Path'      => 0,
                'File::Basename'  => 0,
                'IO::String'      => '1.08',
                # XXX: Can't use Scalar::Defer 0.11 (or possibly later) until some things
                # XXX: are sorted out.  See: http://rt.cpan.org/Ticket/Display.html?id=31039
                # XXX: Scalar::Defer 0.18 seems to work again, but I'm still not using it.
                #'Scalar::Defer'   => 0.18,
                'Rose::Object'    => '0.854',
                'Rose::DateTime'  => '0.532',
                'Rose::URI'       => '0.021',
              },
              clean => { FILES => 't/tmplib/* t/tmplib' },
              ($MM_Version >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
              ($MM_Version >= 6.31 ? (LICENSE => 'perl') : ()),
              ($MM_Version <= 6.44 ? () : 
              (META_MERGE => 
              {
                resources =>
                {
                  license     => 'http://dev.perl.org/licenses/',
                  homepage    => 'http://rosecode.org',
                  bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTML-Objects',
                  repository  => 'https://github.com/siracusa/rose/tree/master/modules/Rose-HTML-Objects',
                  MailingList => 'http://groups.google.com/group/rose-html-objects',
                },
              })));
