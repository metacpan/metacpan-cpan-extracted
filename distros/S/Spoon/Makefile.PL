use inc::Module::Install;
require File::Spec;

name        'Spoon';
all_from    'lib/Spoon.pm';

requires(qw(
    perl 5.6.1
    Spiffy 0.22
    IO::All 0.32
    Template 2.10
    Time::HiRes 0
    URI 0
    DB_File 0
));

clean_files(
    File::Spec->catdir(qw(t tmp)),
    File::Spec->catdir(qw(t output)),
);

WriteAll;
