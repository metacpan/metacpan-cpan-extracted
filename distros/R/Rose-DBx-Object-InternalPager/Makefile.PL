use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Rose::DBx::Object::InternalPager',
    'VERSION_FROM' => 'InternalPager.pm', # finds $VERSION
    'PREREQ_PM'    => {
      Log::Log4perl    => 1,
      DBI              => 1,
      File::Temp       => 0,
      Test::More       => 0,
      Rose::DB         => 0.731,
      Rose::DB::Object => 0.758,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'InternalPager.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
