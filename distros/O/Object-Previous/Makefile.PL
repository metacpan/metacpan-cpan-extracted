use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Object::Previous',
    VERSION_FROM => 'Previous.pm',
    AUTHOR       => 'Paul Miller <jettero@cpan.org>',

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006001,
            META_MERGE => {
                keywords => ['object', 'strange'],
                resources=> {
                    repository => 'http://github.com/jettero/object--previous/',
                },
            },

        LICENSE	=> 'Perl Artistic',
    ) : ()),

);
