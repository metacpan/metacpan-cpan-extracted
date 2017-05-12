#
# $Id: Makefile.PL 22 2015-01-04 16:42:47Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::SinFP3::Plugin::Signature',
   VERSION_FROM  => 'lib/Net/SinFP3/Plugin/Signature.pm',
   ABSTRACT_FROM => 'lib/Net/SinFP3/Plugin/Signature.pm',
   LICENSE       => 'artistic',
   PREREQ_PM     => {
      'Net::SinFP3' => 0,
      'Class::DBI'  => 0,
   },
   EXE_FILES => [ 'bin/sinfp3-plugin-add-signature.pl', 'bin/sinfp3-export.sh',
                  'bin/sinfp3-exportp.sh',
                  'bin/sinfp3-input-signature-output-addsignature.sh',
                ],
   AUTHOR    => 'GomoR <gomor_at_metabrik.org>',
   MIN_PERL_VERSION => '5.6.1',
);
