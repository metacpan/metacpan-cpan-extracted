use strict;
use warnings;

use Test::More tests => 14;
use Template;
use JSON qw/from_json to_json/;

BEGIN {
    use_ok 'Template::Plugin::JSON::Escape';
}

{
    my $vars = {
        blah => { foo => "bar" },
        baz  => "ze special string wis some ' qvotes\"",
        oink => [ 1..3 ],
    };
    my $tt = Template->new;
    my $ret = $tt->process(
        \q{
            [%~ USE JSON.Escape( pretty => 1 ) ~%]
            { "blah":[% blah.json %], "baz":[% baz.json %], "oink":[% oink.json %] }
        },
        $vars,
        \my $out,
    );

    ok $ret, "template processing" or diag $tt->error;
    like $out, qr/\{\W*foo\W*:\W*bar\W*\}/, "output seems OK";
    like $out, qr/\n/, "pretty output";
    is_deeply from_json( $out ), $vars, "round tripping";
}

{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };
    my $tt = Template->new;
    my $ret = $tt->process(
        \q{
            [%~ USE JSON.Escape ~%]
            [%~ SET foo = [ 1, 2, 3 ]; foo.json ~%]
        },
        {},
        \my $out,
    );

    ok $ret, "template processing" or diag $tt->error;
    is $warnings, 0, "no warning";
}

{
    # pass JSON to the template
    my $tt = Template->new;
    my $ret = $tt->process(
        \q{
            [%~ USE JSON.Escape ~%]
            [%~ val = JSON.Escape.json_decode(json_string) ~%]
            [%~ 'ok' IF val.blah.foo == 'bar' ~%]
        },
        { json_string => '{ "blah": { "foo": "bar" }, "oink": [1, 2, 3] }' },
        \my $out,
    );

    ok $ret, "template processing" or diag $tt->error;
    is $out, 'ok', 'match on extract';
}

{
    my $tt = Template->new;
    my $ret = $tt->process(
        \q{
            [%~ USE JSON.Escape ~%]
            [%~ data.json ~%]
        },
        { data => { foo => 'bar & baz <3' } },
        \my $out,
    );

    ok $ret, "template processing" or diag $tt->error;
    unlike $out, qr/[<&]/, 'escape special characters';
}

{
    my $data = { foo => 'bar & baz <3' };
    my $tt = Template->new;
    my $ret = $tt->process(
        \q{
            [%~ USE JSON.Escape ~%]
            [%~ string | json ~%]
        },
        { string => to_json( $data ) },
        \my $out,
    );

    ok $ret, "template processing" or diag $tt->error;
    unlike $out, qr/[<&]/, 'escape special characters by filter';
    is_deeply from_json( $out ), $data, 'still valid json'
}
