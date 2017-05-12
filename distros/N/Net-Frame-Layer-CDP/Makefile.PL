#
# $Id: Makefile.PL 49 2009-05-31 13:15:34Z VinsWorldcom $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::CDP',
   VERSION_FROM  => 'lib/Net/Frame/Layer/CDP.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/CDP.pm',
   AUTHOR        => 'Michael Vincent <vin at vinsworld dot com>',
   PREREQ_PM     => {
      Net::Frame => 1.09,
   },
);
