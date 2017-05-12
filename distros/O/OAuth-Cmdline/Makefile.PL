######################################################################
# Makefile.PL for OAuth::Cmdline
# 2014, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/oauth-cmdline.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'OAuth::Cmdline',
    'VERSION_FROM' => 'lib/OAuth/Cmdline.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl         => 1,
        Moo                   => 1,
        URI                   => 1,
        YAML                  => 0.90,
        HTTP::Request::Common => 1,
        JSON                  => 1,
        LWP::UserAgent        => 1,
        MIME::Base64          => 1,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/OAuth/Cmdline.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
