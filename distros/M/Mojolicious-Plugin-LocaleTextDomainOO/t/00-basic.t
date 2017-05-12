use Mojo::Base -strict;
use File::Spec;
use File::Basename;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use utf8;

plugin 'LocaleTextDomainOO';

my $locale_dir = File::Spec->catdir( dirname(__FILE__), 'locale' );
app->lexicon(
    {
        search_dirs => [$locale_dir],
        data        => [ '*::' => '*.po' ],
    }
);

subtest 'method' => sub {
    my $loc = app->locale;
    is ref $loc, 'Locale::TextDomain::OO::Singleton::Translator',
      'right object';

    $loc->category('LC_MESSAGES');
    is $loc->category, 'LC_MESSAGES', 'right category';

    $loc->domain('MyDomain');
    is $loc->domain, 'MyDomain', 'right domain';

};

done_testing();
