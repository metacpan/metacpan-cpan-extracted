require 5.006;

use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if($MM_Version =~ /_/) # dev version
{
  $MM_Version = eval $MM_Version;
  die $@  if($@);
}

WriteMakefile(NAME          => 'Rose::DB::Object',
              ABSTRACT_FROM => 'lib/Rose/DB/Object.pm',
              VERSION_FROM  => 'lib/Rose/DB/Object.pm',
              ($^O =~ /darwin/i ? (dist => { DIST_CP => 'cp' }) : ()), # Avoid Mac OS X ._* files
              PREREQ_PM =>
              {
                'Cwd'                  => 0,
                'Data::Dumper'         => '2.121', 
                'File::Path'           => 0,
                'File::Spec'           => 0,
                'DBI'                  => '1.40',
                'DateTime'             => 0,
                'Time::Clock'          => '1.00',
                'Test::More'           => 0,
                'Bit::Vector'          => 0,
                'Scalar::Util'         => 0,
                'Math::BigInt'         => '1.77',
                'Clone'                => '0.29',
                #'Scalar::Util::Clone' => '0.04',
                'Rose::DateTime::Util' => '0.532',
                'Rose::Object'         => '0.854',
                'Rose::DB'             => '0.782',
              },
              clean => { FILES => "t/*.db" },
              AUTHOR => 'John Siracusa <siracusa@gmail.com>',
              ($MM_Version >= 6.48 ? (MIN_PERL_VERSION => '5.6.0') : ()),
              ($MM_Version >= 6.31 ? (LICENSE => 'perl') : ()),
              ($MM_Version <= 6.44 ? () : 
              (META_MERGE => 
              {
                resources =>
                {
                  license     => 'http://dev.perl.org/licenses/',
                  homepage    => 'http://rosecode.org',
                  bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DB-Object',
                  repository  => 'https://github.com/siracusa/rose/tree/master/modules/Rose-DB-Object',
                  MailingList => 'http://groups.google.com/group/rose-db-object',
                },
              })));

