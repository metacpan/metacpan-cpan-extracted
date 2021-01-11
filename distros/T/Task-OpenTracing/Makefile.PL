use ExtUtils::MakeMaker::CPANfile;
use Module::CPANfile;

# ExtUtils::MakeMaker::CPANfile doesn't support optional features
my $cpanfile = Module::CPANfile->load('cpanfile');
my %opt_features;
foreach my $feature ($cpanfile->features) {
    $opt_features{ $feature->identifier } = {
        description => $feature->description,
        prereqs     => $feature->prereqs->as_string_hash,
    };
}

WriteMakefile(
    'NAME'             => 'Task::OpenTracing',
    'VERSION_FROM'     => 'lib/Task/OpenTracing.pm',
    'ABSTRACT_FROM'    => 'lib/Task/OpenTracing.pm',
    'LICENSE'          => 'artistic2',
    'MIN_PERL_VERSION' => '5.014',
    test               => { TESTS => 't/*.t', },
    'META_MERGE'       => {
        'meta-spec'         => { version => 2 },
        'optional_features' => \%opt_features,
    },
);
