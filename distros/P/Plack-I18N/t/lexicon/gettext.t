use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::Requires {'Locale::Maketext::Lexicon' => '0'};

use Plack::I18N::Lexicon::Gettext;

subtest 'throws when no i18n_class' => sub {
    like exception { _build_lexicon(i18n_class => undef) },
      qr/i18n_class required/;
};

subtest 'throws when no locale dir' => sub {
    like exception { _build_lexicon(locale_dir => undef) },
      qr/locale_dir required/;
};

subtest 'detects languages' => sub {
     my $lexicon = _build_lexicon();

     is_deeply [$lexicon->detect_languages], [qw/en ru/];
};

subtest 'builds class' => sub {
     my $lexicon = _build_lexicon();

    ok MyApp::I18N->get_handle('en');
};

sub _build_lexicon {
    Plack::I18N::Lexicon::Gettext->new(
        i18n_class => 'MyApp::I18N',
        locale_dir => 't/locale',
        lexicon    => 'gettext',
        @_
    );
}

done_testing;
