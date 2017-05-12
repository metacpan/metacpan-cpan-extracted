
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Net::SMTP::OneLiner',
    'VERSION_FROM' => 'OneLiner.pm',
    AUTHOR         => 'Paul Miller <jettero@cpan.org>',

    PREREQ_PM => {
        'Net::SMTP' => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['smtp', 'one liner', 'one off', 'easy', 'simple'],
                resources=> {
                    repository => 'http://github.com/jettero/net--smtp--oneliner',
                },
            },

        LICENSE	=> 'Perl Artistic',
    ) : ()),

);
