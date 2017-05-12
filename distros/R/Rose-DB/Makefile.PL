require 5.006;

use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if($MM_Version =~ /_/) # dev version
{
  $MM_Version = eval $MM_Version;
  die $@  if($@);
}

WriteMakefile(NAME         => 'Rose::DB',
              VERSION_FROM => 'lib/Rose/DB.pm',
              ($^O =~ /darwin/i ? (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                'DBI'                      => 0,
                'Clone::PP'                => 0,
                'Bit::Vector::Overload'    => '6.4',
                'DateTime::Format::Pg'     => '0.11',
                'DateTime::Format::MySQL'  => 0,
                'DateTime::Format::Oracle' => 0,
                'DateTime::Duration'       => 0,
                'Test::More'               => 0,
                'Rose::Object'             => '0.854',
                'Rose::DateTime::Util'     => '0.532',
                'Time::Clock'              => 0,
                'SQL::ReservedWords'       => 0,
                'Scalar::Util'             => 0,
              },
              clean => { FILES => "t/*.db" },
              ($MM_Version >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
              ($MM_Version >= 6.31 ? (LICENSE => 'perl') : ()),
              ($MM_Version <= 6.44 ? () : 
              (META_MERGE => 
              {
                resources =>
                {
                  license     => 'http://dev.perl.org/licenses/',
                  homepage    => 'http://rosecode.org',
                  bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DB',
                  repository  => 'https://github.com/siracusa/rose/tree/master/modules/Rose-DB',
                  MailingList => 'http://groups.google.com/group/rose-db-object',
                },
              })));
