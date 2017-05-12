use strict;
use warnings;
use Module::Build;

my %modules = (
        #  Template::Benchmark itself.
        'Template::Benchmark'       => 0,

        #  Optional bits for extra benchmark_template_engines behaviour.
        'Term::ProgressBar::Simple' => 0,
        'JSON::Any'                 => 0,

        #  File::Spec needed by plugins for:
        #    Mojo::Template, Tenjin, Text::MicroMason, Text::Templ.
        'File::Spec'                => 0,

        #  IO::File needed by plugins for:
        #    Mojo::Template, Tenjin.
        'IO::File'                  => 0,

        'HTML::Template'            => 0,
        'HTML::Template::Compiled'  => 0,
        'HTML::Template::Expr'      => 0,
        'HTML::Template::JIT'       => 0,
        'HTML::Template::Pro'       => 0,
        'Mojo'                      => 0,
        'Mojo::Template'            => 0,
        'NTS::Template'             => 0,
        'Template::Alloy'           => 0,
        #  Lots of extras here...
        'Template::Sandbox'         => 0,
        'Cache::CacheFactory'       => 0,
        'Cache::Cache'              => 0,
        'Cache::FastMemoryCache'    => 0,
        'Cache::FastMmap'           => 0,
        'CHI'                       => 0,
        'Template::Tiny'            => 0,
        'Template'                  => 0,
        'Template::Stash::XS'       => 0,
        'Template::Parser::CET'     => 0,
        #  pre-0.05 Tenjin was an incompatible API change
        'Tenjin'                    => '0.05',
        'Text::ClearSilver'         => 0,
        'Text::MicroMason'          => 0,
        'Text::MicroTemplate'       => 0,
        'Text::MicroTemplate::Extended' => 0,
        'Text::Template'            => 0,
        'Text::Template::Simple'    => 0,
        'Text::Tmpl'                => 0,
        #  0.1030 required for TextXlsateTT.
        'Text::Xslate'              => '0.1030',
        'Text::Xslate::Bridge::TT2' => 0,
    );

#  Prune the unsafe ones on windows.
delete @modules{ qw/
    HTML::Template::Compiled
    HTML::Template::JIT
    NTS::Template
    Template::Alloy
    Template::Tiny
    Text::ClearSilver
    Text::Template::Simple
    Text::Tmpl
    Text::Xslate
    Text::Xslate::Bridge::TT2
    Term::ProgressBar::Simple
    / }
    if $^O =~ /MSWin/;

my $builder = Module::Build->new(
    module_name         => 'Task::Template::Benchmark',
    license             => 'perl',
    dist_author         => q{Sam Graham <libtemplate-benchmark-perl@illusori.co.uk>},
    dist_version_from   => 'lib/Task/Template/Benchmark.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        %modules,
    },
    sign => 1,
    dynamic_config => 1,
);

$builder->create_build_script();
