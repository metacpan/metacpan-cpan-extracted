use ExtUtils::MakeMaker;
use 5.006;
my $module_file = 'lib/Object/Disoriented.pm';
WriteMakefile(
    NAME          => 'Object::Disoriented',
    AUTHOR        => 'Aaron Crane <arc@cpan.org>',
    ABSTRACT_FROM => $module_file,
    VERSION_FROM  => $module_file,
);
