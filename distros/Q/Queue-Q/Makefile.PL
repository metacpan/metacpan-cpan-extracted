use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Queue::Q',
    VERSION_FROM      => 'lib/Queue/Q.pm', # finds $VERSION
    EXE_FILES         => [qw(scripts/fifo-cli)],
    PREREQ_PM         => {
      'Redis' => '1.955',
      'Redis::ScriptCache' => '0.03',
      'Sereal::Encoder' => '0.10',
      'Sereal::Decoder' => '0.10',
      'Class::XSAccessor' => '0.12',
      'List::Util' => '0',
      'Scalar::Util' => '0',
      'Time::HiRes' => '0',
      'constant' => '0',
      'Carp' => '0',
      'Digest::SHA1' => '0',
      'parent' => '0',
      'File::Spec' => '0',
      'Test::More' => '0.88',
      'JSON::XS' => '0',
      'File::Slurp' => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Queue/Q.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
