package Sed;

use strict;
use ExtUtils::MakeMaker;

my @ppd;

if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'darren chamberlain <darren@cpan.org>',
    ABSTRACT  => "A sed(1)-like stream editor",
  );
}

WriteMakefile(
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => "Sed.pm",
    @ppd,
);


sub MY::postamble {
  return '' unless $] >= 5.00503;
<<'PPD';

dist : ppd

PPD
}

