use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Stable::Module',
    'VERSION_FROM'  => 'lib/Stable/Module.pm',
    'ABSTRACT_FROM' => 'lib/Stable/Module.pm',
    'PREREQ_PM'     => { },
    'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
);

__END__
