use 5.008001;
use utf8;
use strict;
use warnings;

use ExtUtils::MakeMaker;

# Make setting optional MakeMaker parameters more readable.
sub OPTIONAL {
   return () unless $ExtUtils::MakeMaker::VERSION ge shift;
   return @_;
}

WriteMakefile(
   NAME => 'Muldis::Rosetta',
   VERSION => '0.16.0',
   ABSTRACT => 'Full-featured truly relational DBMS in Perl',
   AUTHOR => 'Darren Duncan <darren@DarrenDuncan.net>',
   PREREQ_PM => {
      # This list is a copy of "META_ADD:[configure_|build_|]requires"
      # where the other is canonical; this list is for use by MakeMaker
      # itself, which in general wouldn't see the info in the other lists,
      # as the other lists are primarily used when generating the META.yml.
      'Carp::Always' => '0.09',
      'Class::MOP' => '0.98',
      'ExtUtils::MakeMaker' => '6.48',
      'Moose' => '0.98',
      'Moose::Role' => '0.98',
      'MooseX::Singleton' => '0.22',
      'namespace::autoclean' => '0.09',
      'Test::Moose' => '0.98',
      'Test::More' => '0.92',
      'Try::Tiny' => '0.04',
   },
   OPTIONAL( '6.48',
      MIN_PERL_VERSION => '5.008001',
   ),
   OPTIONAL( '6.31',
      LICENSE => 'lgpl',
   ),
   OPTIONAL( '6.46',
      # Use META_ADD instead of META_MERGE so that we can remove
      # any build-time dependencies that MakeMaker will put into
      # the requires field.  (Comment From DBD::SQLite; do *we* need that?)
      META_ADD => {
         configure_requires => {
            'ExtUtils::MakeMaker' => '6.48',
         },
         build_requires => {
            'ExtUtils::MakeMaker' => '6.48',
            # These are bundled with Perls 5.10.1+ but not earlier Perls.
            'Test::More' => '0.92',
            # These are not bundled with any version of Perl.
            'Carp::Always' => '0.09',
         },
         requires => {
            # ALWAYS REQUIRES:

            'perl' => '5.008001', # as MIN_PERL_VERSION no affect META.yml
            # These are not bundled with any version of Perl.
            'Class::MOP' => '0.98', # req latest indep of Moose
            'Moose' => '0.98',
            'Moose::Role' => '0.98',
            'MooseX::Singleton' => '0.22',
            'namespace::autoclean' => '0.09',
            'Try::Tiny' => '0.04',

            # VALIDATOR MODULE REQUIRES:

            # These are bundled with Perls 5.10.1+ but not earlier Perls.
            'Test::More' => '0.92',
            # These are not bundled with any version of Perl.
            'Test::Moose' => '0.98',
         },
         resources => {
            homepage => 'http://www.muldis.com/',
            license => 'http://www.fsf.org/licensing/licenses/lgpl.html',
            MailingList => 'http://mm.DarrenDuncan.net/mailman/listinfo',
            repository => 'http://github.com/muldis/Muldis-Rosetta',
         },
      },
   ),
);

1;
