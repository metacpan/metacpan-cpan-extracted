#
# $Id: Makefile.PL 49 2009-05-31 13:15:34Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

my @prereq_pm;
if ($] < 5.014) {
    push @prereq_pm, "Socket::GetAddrInfo";
    push @prereq_pm, 0.21;
}

WriteMakefile(
   NAME          => 'Net::Frame::Layer::NTP',
   VERSION_FROM  => 'lib/Net/Frame/Layer/NTP.pm',
   LICENSE       => 'artistic',
   ABSTRACT_FROM => 'lib/Net/Frame/Layer/NTP.pm',
   AUTHOR        => 'Michael Vincent <vin at vinsworld dot com>',
   PREREQ_PM     => {
      Net::Frame => 1.09,
      @prereq_pm
   },
);
