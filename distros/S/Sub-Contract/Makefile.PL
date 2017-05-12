use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Sub::Contract',
    VERSION_FROM      => 'lib/Sub/Contract.pm',
    PREREQ_PM         => {
      'accessors' => 0.02,
      'Sub::Name' => 0.02,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Sub/Contract.pm',
       AUTHOR         => 'Erwan Lemonnier <erwan@cpan.org>') : ()),
);

