use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";

my $meta_merge = {
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mschilli/skeletor-template-quick.git',
        },
    }
};

WriteMakefile(
    'NAME'         => 'Skeletor::Template::Quick',
    'VERSION_FROM' => 'lib/Skeletor/Template/Quick.pm', # finds $VERSION
    'PREREQ_PM'    => {
        'YAML'                    => "1.0",
        'App::Skeletor'           => '0.003',
    }, # e.g., Module::Name => 1.1
    'EXE_FILES'    => ["eg/skel"],
    $ExtUtils::MakeMaker::VERSION >= 6.50 ? (%$meta_merge) : (),
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Skeletor/Template/Quick.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);

{
    package MY;
    use File::ShareDir::Install qw(postamble);
}
