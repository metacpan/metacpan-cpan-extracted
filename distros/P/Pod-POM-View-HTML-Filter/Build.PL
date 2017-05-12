use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Pod::POM::View::HTML::Filter',
    dist_author        => 'Philippe "BooK" Bruhat <book@cpan.org>',
    dist_version_from  => 'lib/Pod/POM/View/HTML/Filter.pm',
    requires           => {
        'Test::More' => 0,
        'Pod::POM'   => '0.17',
    },
    recommends         => {
        'PPI'                      => '1.111',
        'PPI::HTML'                => '1.06',
        'Perl::Tidy'               => '20031021',
        'Syntax::Highlight::HTML'  => '0.02',
        'Syntax::Highlight::Shell' => '0.02',
        'Syntax::Highlight::Engine::Kate' => '0.02',
        'Text::WikiFormat'         => '0.76',
    },
    license            => 'perl',
    add_to_cleanup     => ['Pod-POM-View-HTML-Filter-*'],
);

$builder->create_build_script();
