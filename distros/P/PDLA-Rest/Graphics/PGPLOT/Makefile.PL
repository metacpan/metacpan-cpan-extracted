use strict;
use warnings;
use ExtUtils::MakeMaker;

eval { require PGPLOT };
if ($@) {
    write_dummy_make("Not building PDL::Graphics::PGPLOT, PGPLOT not installed");
    return;
}

WriteMakefile(
	      'NAME'  	=> 'PDLA::Graphics::PGPLOT',
              'VERSION_FROM' => '../../lib/PDLA/Rest.pm',
	      'DIR' => ['Window'],
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
