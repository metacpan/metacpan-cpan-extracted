use strict;
use warnings;
use Apache2;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => "OpenFrame::Segment::Apache2",
  VERSION_FROM => "lib/OpenFrame/Segment/Apache2.pm",
  PREREQ_PM    => {
    'mod_perl' => '1.9908',
    'OpenFrame::AppKit' => '1.00',
    'LWP::UserAgent' => '2.001',
    'HTTP::Cookies' => '1.25',
    'URI' => '1.21',
    'Template' => '2.08',
  },
);

