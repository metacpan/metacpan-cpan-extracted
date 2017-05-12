use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

###############################################################################
# Write Makefile
WriteMakefile(
    'NAME'              => 'Rose::DBx::Object::Loader::FormMaker',
    'VERSION_FROM'      => 'lib/Rose/DBx/Object/Loader/FormMaker.pm',
    'AUTHOR'            => 'Adam Prime (adam.prime@utoronto.ca)',
    'PREREQ_PM'         => {
        'Rose::DB::Object'      => 0.765,
        'Rose::HTML::Objects'    => 0.549,
        'Rose::DBx::TestDB'     => 0.04,
        'Path::Class'           => 0,
        },
    );
