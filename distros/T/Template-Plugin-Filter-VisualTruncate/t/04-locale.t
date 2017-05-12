use strict;
use warnings;

use Test::Base;
use Template;
use Encode;
use encoding ':_get_locale_encoding';

plan tests => 19;

use_ok('Template::Plugin::Filter::VisualTruncate');
use_ok('Template::Plugin::Filter::VisualTruncate::Locale');

TODO: {
    local $TODO = "various reasons.";

    my $tt = Template->new({
        PLUGINS => {
            VisualTruncate => 'Template::Plugin::Filter::VisualTruncate'
        }
    });

    ok($tt);
    ok(UNIVERSAL::isa($tt, 'Template'));
    ok($tt->process(\'[% USE VisualTruncate \'locale\' %]'));

    my $encoding = find_encoding(_get_locale_encoding());

    sub default_sanitize {
        my $input = $_[0];
        my $output;

        Encode::from_to($input, 'utf8', $encoding, 1);

        $tt->process(\$input, undef, \$output);
        return $output;
    }

    SKIP: {
        skip "Cannot get system locale encoding.", 14 unless $encoding;

        my $text = 'abcd';

        Encode::from_to($text, 'utf8', $encoding, 1);

        ok(my $obj = Template::Plugin::Filter::VisualTruncate::Locale->new);
        is($obj->width($text), 4);

        spec_file('t/test_base_spec.txt');
        filters('default_sanitize');
        run_is 'input' => 'expected';
    };
};
