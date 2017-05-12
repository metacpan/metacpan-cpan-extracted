######################################################################
# Makefile.PL for Net::SSH::AuthorizedKeysFile
# 2005, Mike Schilli <m@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'http://github.com/mschilli/net-ssh-authorizedkeysfile-perl',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Net::SSH::AuthorizedKeysFile',
    'VERSION_FROM' => 'lib/Net/SSH/AuthorizedKeysFile.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Test::More       => 0,
        Text::ParseWords => 0,
        Log::Log4perl    => 1,
        File::Temp       => 0,
        File::Copy       => 0,
        Digest::MD5      => 0,
        File::Spec       => 0,
    }, # e.g., Module::Name => 1.1
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    'EXE_FILES'    => [ 'eg/authorized-keys-test' ],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/SSH/AuthorizedKeysFile.pm',
       AUTHOR     => 'Mike Schilli <m@perlmeister.com>') : ()),
);
