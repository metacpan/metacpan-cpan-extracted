

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Rose::HTMLx::Form::DBIC',
    VERSION_FROM => 'lib/Rose/HTMLx/Form/DBIC.pm', # finds \$VERSION
    AUTHOR       => 'Zbigniew Lukasiak',
    ABSTRACT     => 'Integration of Rose::HTML::Form with DBIx::Class',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Rose::Object' => 0.85,
                     'Rose::HTML::Object' => '0.600',
                     'DBIx::Class::ResultSet::RecursiveUpdate' => 0,
                     'Moose' => 0,
                     'String::Random' => 0,
                     'Template' => 0,
                     'Scalar::Util' => '1.19',
                    },
   LICENSE=>'perl', 
);

