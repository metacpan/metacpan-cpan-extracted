######################################################################
# Makefile.PL for Net::Evernote::Simple
# 2012, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/net-evernote-simple.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Net::Evernote::Simple',
    'VERSION_FROM' => 'lib/Net/Evernote/Simple.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl => 1.0,
        YAML          => 0.71,
        File::Temp    => 0.22,
        Thrift        => 0.6.1,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/Evernote/Simple.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
