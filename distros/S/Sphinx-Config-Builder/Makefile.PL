use 5.008008;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ( $mm_ver =~ /_/ ) {    # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Sphinx::Config::Builder',
    VERSION_FROM => 'lib/Sphinx/Config/Builder.pm',  # finds $VERSION
    PREREQ_PM    => { 'Test::More' => '0.99' },      # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Sphinx/Config/Builder.pm',    # retrieve abstract from module
            AUTHOR => 'B. Estrade <estrabd@gmail.com>'
          )
        : ()
    ),

    (
        $mm_ver >= 6.31
        ? ( LICENSE => 'perl' )
        : ()
    ),

    (
        $mm_ver <= 6.45
        ? ()
        : (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Sphinx-Config-Builder',
                    repository => {
                        type => 'git',
                        web => 'https://github.com/estrabd/perl-Sphinx-Config-Builder',
                        url => 'git://github.com/estrabd/perl-Sphinx-Config-Builder.git',
                    },
                },
            }
        )
    ),

);
