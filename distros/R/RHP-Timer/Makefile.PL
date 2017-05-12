use 5.008006;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME      => 'RHP::Timer',
              VERSION   => '0.1',
              PREREQ_PM => {Time::HiRes => '1.65'},
              (
               ABSTRACT => 'The RedHotPenguin high resolution timer abstration',
               AUTHOR   => 'Fred Moyer <fred@redhotpenguin.com'
              ),
             );
1;
