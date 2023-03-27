use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Strict::Perl},
    'VERSION'   => q{2023.03},
    'ABSTRACT'  => q{Perl module to restrict old/unsafe constructs},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'Switch' => '0',
        'Thread' => '0',
        'encoding' => '0',
        'lib' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'threads' => '0',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
