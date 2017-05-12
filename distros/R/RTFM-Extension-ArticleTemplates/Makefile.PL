use inc::Module::Install;

RTx         'RTFM-Extension-ArticleTemplates';
license     'GPL version 2';
all_from    'lib/RTFM/Extension/ArticleTemplates.pm';
readme_from 'lib/RTFM/Extension/ArticleTemplates.pm';

build_requires 'Test::More';
{ # check RT version
    my @v = split /\./, "$RT::VERSION";
    if ($v[0] >= 4) {
        die "\n\nThis module doesn't work with RT 4.x, you have $RT::VERSION.\nUse RT::Extension::ArticleTemplates instead.\n\n";
    }
}

no_index('package' => 'RT::FM::Article');

sign;

auto_install;
WriteAll;

