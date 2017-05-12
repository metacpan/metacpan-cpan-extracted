use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'MojoX::Session::Store::MongoDB',
    VERSION_FROM => 'lib/MojoX/Session/Store/MongoDB.pm',    # finds $VERSION
    PREREQ_PM    => {
        'MongoDB'      => 0,
        'Data::Dumper' => 0,
        'Test::More'   => 0,
        'Mojo'         => 0.991251,
        'MojoX::Session' => 0.15,
        'namespace::clean' => 0,
    },
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          ( ABSTRACT_FROM => 'lib/MojoX/Session/Store/MongoDB.pm'
            ,    # retrieve abstract from module
            AUTHOR => 'Ask Bjørn Hansen <ask@develooper.com>'
          )
        : ()
    ),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    INC => '-I.'
);
