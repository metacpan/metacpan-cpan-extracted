use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Rose::HTMLx::Form::Field::Autocomplete',
    VERSION_FROM      => 'lib/Rose/HTMLx/Form/Field/Autocomplete.pm', # finds $VERSION
    PREREQ_PM         => {

          'Rose::HTML::Form::Field::Text' => 0.01

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Rose/HTMLx/Form/Field/Autocomplete.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <perl@peknet.com>') : ()),
);
