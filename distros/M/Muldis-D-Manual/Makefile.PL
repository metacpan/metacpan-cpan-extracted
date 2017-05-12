use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# Make setting optional MakeMaker parameters more readable.
sub OPTIONAL {
   return () unless $ExtUtils::MakeMaker::VERSION ge shift;
   return @_;
}

WriteMakefile(
   NAME => 'Muldis::D::Manual',
   VERSION => '0.9.0',
   ABSTRACT => 'Muldis D language and implementations manual',
   AUTHOR => 'Darren Duncan <darren@DarrenDuncan.net>',
   PREREQ_PM => {},
   OPTIONAL( '6.48',
      MIN_PERL_VERSION => '5.006',
   ),
   OPTIONAL( '6.31',
      LICENSE => 'gpl_3',
   ),
   OPTIONAL( '6.46',
      META_ADD => {
         requires => {
            'perl' => '5.006', # as MIN_PERL_VERSION no affect META.yml
         },
         resources => {
            homepage => 'http://www.muldis.com/',
            license => 'http://www.fsf.org/licensing/licenses/gpl.html',
            MailingList => 'http://mm.darrenduncan.net/mailman/listinfo',
            repository => 'http://github.com/muldis/Muldis-D-Manual',
         },
      },
   ),
);

1;
