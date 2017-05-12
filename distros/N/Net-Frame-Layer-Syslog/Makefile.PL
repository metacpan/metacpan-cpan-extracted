#
# $Id: Makefile.PL 49 2009-05-31 13:15:34Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME          => 'Net::Frame::Layer::Syslog',
   VERSION_FROM  => 'lib/Net/Frame/Layer/Syslog.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/Syslog.pm',
   AUTHOR        => 'Michael Vincent <vin at vinsworld dot com>',
   PREREQ_PM     => {
      Net::Frame => 1.09,
   },
);
