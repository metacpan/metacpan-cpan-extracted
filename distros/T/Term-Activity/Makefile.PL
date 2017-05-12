use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Process Activity Display Module",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Term::Activity',
  VERSION  => '1.20',

  PREREQ_PM => {
          'Test::More' => 0,
          'Term::Size' => 0,
          'Test::Simple' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Term::Activity' => {
                                'version' => '1.20',
                                'file' => 'lib/Term/Activity.pm'
                              }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Term-Activity.git',
                        web  => 'http://github.com/bennie/perl-Term-Activity',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Term-Activity',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.6.0' )
  )

);