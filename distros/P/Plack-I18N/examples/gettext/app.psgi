use strict;
use warnings;

use File::Basename qw(dirname);

BEGIN {
    unshift @INC, dirname(__FILE__) . '/../../lib';
}

use Encode ();
use Plack::Builder;
use Plack::I18N;

my $i18n = Plack::I18N->new(
    lexicon    => 'gettext',
    locale_dir => dirname(__FILE__) . '/locales'
);

builder {
    enable 'I18N', i18n => $i18n;

    sub {
        my $env = shift;

        my $handle = $env->{'plack.i18n.handle'};

        my $translated = Encode::encode('UTF-8', $handle->maketext('Hello'));

        [
            200,
            ['Content-Type' => 'text/html; charset=utf-8'],
            [<<"EOF"
<html>
Translated: $translated<br />

<a href="/">English</a>
<a href="/ru/">Russian</a>
</html>
EOF
            ]
        ];
    };
};
