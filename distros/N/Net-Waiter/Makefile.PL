use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Net::Waiter',
  VERSION_FROM    => 'lib/Net/Waiter.pm',
  META_MERGE      => {
                     'meta-spec'     => { 
                                        version => 2 
                                        },
                      
                     resources       => {
                                        repository => {
                                                      type => 'git',
                                                      url  => 'https://github.com/cade-vs/perl-net-waiter.git',
                                                      web  => 'https://github.com/cade-vs/perl-net-waiter',
                                                      },
                                        },
                     },
);
