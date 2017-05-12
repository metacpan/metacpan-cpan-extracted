# vi:set syntax=perl:

use strict;
use warnings;

my @v = eval {
    my $b = bless {'v1'=>1, 'v2'=>2}, "blarg";
    return keys %$b;
};

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Statistics::Basic',
    'VERSION_FROM'  => 'Basic.pm',

    'PREREQ_PM'     => { 
        'Number::Format' => 1.42,
        'Scalar::Util'   => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006,
            META_MERGE => {
                keywords => ['stats','statistics', 'mean', 'average', 'correlation'],
                resources=> {
                    repository => 'http://github.com/jettero/statistics--basic',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),

);
