use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Net::BCCN',
  VERSION_FROM    => 'lib/Net/BCCN.pm',
  META_MERGE      => {
                     'meta-spec'     => {
                                        version => 2
                                        },

                     resources       => {
                                        repository => {
                                                      type => 'git',
                                                      url  => 'https://github.com/cade-vs/bccn.git',
                                                      web  => 'https://github.com/cade-vs/bccn',
                                                      },
                                        },
                     },
);
