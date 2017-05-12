use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   'NAME' => 'PDLA::Perldl2::Plugin',
   'VERSION' => '2.001',
   'PM' => {
      'CleanErrors.pm' =>  '$(INST_LIBDIR)/Plugin/CleanErrors.pm',
      'NiceSlice.pm' => '$(INST_LIBDIR)/Plugin/NiceSlice.pm',
      'PDLACommands.pm' => '$(INST_LIBDIR)/Plugin/PDLACommands.pm',
      'PrintControl.pm' => '$(INST_LIBDIR)/Plugin/PrintControl.pm',
   },
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
