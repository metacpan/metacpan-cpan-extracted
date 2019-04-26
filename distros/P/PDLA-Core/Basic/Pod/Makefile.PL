use strict;
use warnings;
use ExtUtils::MakeMaker;

my @pods = map { $_=~s/.pod//; $_ } grep { ! m/Index.pod/ } glob("*.pod");

my @man1 = map { $_.".pod", '$(INST_MAN1DIR)/PDLA::' . $_ . '.$(MAN1EXT)' } @pods;
my @pms  = map { $_.".pod", '$(INST_LIBDIR)/' . $_ .".pod"} @pods;

WriteMakefile(
 'NAME' =>      'PDLA::pod',
 'MAN1PODS' =>  { @man1 },
 'MAN3PODS' =>  { },
 'PM'    =>     { @pms },
 (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
