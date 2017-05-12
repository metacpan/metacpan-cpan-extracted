use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Parse NetApp Weekly Auto Support Files",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Parse::NetApp::ASUP',
  VERSION  => '1.17',

  PREREQ_PM => {
          'Test::More' => 0,
          'Digest::MD5' => '2.5',
          'Data::Dumper' => 0,
          'Test' => 0,
          'Test::Simple' => 0,
          'File::Slurp' => '9999.19',
          'Carp' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Parse::NetApp::ASUP' => {
                                     'version' => '1.17',
                                     'file' => 'lib/Parse/NetApp/ASUP.pm'
                                   }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Parse-NetApp-ASUP.git',
                        web  => 'http://github.com/bennie/perl-Parse-NetApp-ASUP',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Parse-NetApp-ASUP',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006' )
  )

);