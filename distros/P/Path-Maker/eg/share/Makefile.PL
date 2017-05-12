use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => '<?= $arg->{module_name} ?>',
    VERSION_FROM => '<?= $arg->{module_path} ?>',
);
