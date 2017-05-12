use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'ShardedKV::Storage::Rest',
    VERSION_FROM   => 'lib/ShardedKV/Storage/Rest.pm',
    PREREQ_PM      => {
      'Test::More' => 0,
      'Test::HTTP::Server' => 0,
      'File::Temp' => 0,
      'ShardedKV'  => 0,
      'URI'        => 0,
      'Net::HTTP'  => 0,
      'Socket'     => 0,
    },
    ABSTRACT_FROM  => 'lib/ShardedKV/Storage/Rest.pm',
    AUTHOR         => [
        'Andrea Guzzo <xant@cpan.org>',
    ],
);

