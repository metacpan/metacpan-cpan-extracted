use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	      => 'Net::TiVo',
              'VERSION_FROM'  => 'lib/Net/TiVo.pm', 
              'PREREQ_PM'     => {  'XML::Simple'      => 2.08,
                                    'LWP::UserAgent'   => 2,
                                    'Log::Log4perl'    => 0,
                                    'Crypt::SSLeay'    => 0,
                                    'Test::More'       => 0,
                                  },

	      ($] >= 5.005 ?
	       ( 'ABSTRACT_FROM'   => 'lib/Net/TiVo.pm',
		     'AUTHOR'          => 'Christopher Boumenot <boumenot@gmail.com>') : ()),
          );
