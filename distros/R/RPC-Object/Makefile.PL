use ExtUtils::MakeMaker;

WriteMakefile('NAME'		=> 'RPC::Object',
              'VERSION_FROM'	=> 'Object.pm',
              'PREREQ_PM'	=> {}, # e.g., Module::Name => 1.1
              ($] >= 5.005
               ? (AUTHOR     => 'Jianyuan Wu <jwu@cpan.org>')
               : ()),
             );
