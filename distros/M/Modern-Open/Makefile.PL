use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Modern::Open},
    'VERSION'   => q{0.14},
    'ABSTRACT'  => q{Autovivification, Autodie, and 3-args open support},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'Fcntl' => '1.03',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'lib' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
