#
# $Id: Makefile.PL 49 2009-05-31 13:15:34Z gomor $
#
use ExtUtils::MakeMaker;

require v5.10.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::IGMP',
   VERSION_FROM  => 'lib/Net/Frame/Layer/IGMP.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/IGMP.pm',
   AUTHOR        => 'Michael Vincent <vin at vinsworld dot com>',
   PREREQ_PM     => {
      Net::Frame => 1.17,
   },
);
