use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME' => 'PDLA::Transform::Cartography',
  PM => { (map {($_ => '$(INST_LIBDIR)/'.$_)}  <*.pm>), 
          (map {($_ => '$(INST_LIBDIR)/Cartography/'.$_)} <*.fits *.jpg>)},
  (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
