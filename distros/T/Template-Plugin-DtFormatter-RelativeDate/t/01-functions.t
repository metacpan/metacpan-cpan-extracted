use warnings;
use strict;
use utf8;

use Test::Base;
use Data::Dumper;
use DateTime::Format::MySQL;

plan tests => 5 + 1 * blocks;

sub tt {
    my ($input_ref) = @_;

    my $tests_ref = $input_ref->{items};

    $_->{dt} = DateTime::Format::MySQL->parse_datetime($_->{datetime}) for (@$tests_ref);

    my $tt = Template->new(
        { 
            PLUGINS => {
                'DtFormatter.RelativeDate' => 'Template::Plugin::DtFormatter::RelativeDate',
            }
        }
    );

    my $tmpl = <<'';
[%- USE DtFormatter.RelativeDate -%]
[%- SET formatter = DtFormatter.RelativeDate.formatter("%Y-%m-%d", lang) -%]
[%- FOR item = items -%]
[% formatter(item.dt) -%], [%- item.name %]
[% END -%]

    $tt->process(\$tmpl, { items => $tests_ref, lang => $input_ref->{lang} }, \my $output);

    $output;
}

{
    use_ok("Template");
    use_ok("Template::Plugin::DtFormatter::RelativeDate");

    my $tt;
    ok( $tt = Template->new({}), "get TT instance." );
    ok( $tt = Template->new(
            { 
                PLUGINS => {
                    'DtFormatter.RelativeDate' => 'Template::Plugin::DtFormatter::RelativeDate',
                }
            }
        ), "get TT instance with plugin." );
    ok( $tt->process(\'[% USE DtFormatter.RelativeDate %]'), "USE in template." );
}

no warnings qw(once);
$Template::Plugin::DtFormatter::RelativeDate::MOCK = 1;
run_is input => 'expected';

__END__
=== formatter, lang=en
--- input yaml tt
lang: en
items:
    -
        name: yesterday - 1
        datetime: 2007-07-26 12:23:34
    -
        name: yesterday
        datetime: 2007-07-27 12:23:34
    -
        name: today
        datetime: 2007-07-28 12:23:34
    -
        name: tommorow
        datetime: 2007-07-29 12:23:34
    -
        name: tomorrow + 1
        datetime: 2007-07-30 12:23:34
--- expected
2007-07-26, yesterday - 1
Yesterday, yesterday
Today, today
Tomorrow, tommorow
2007-07-30, tomorrow + 1
=== formatter, lang=ja
--- input yaml tt
lang: ja
items:
    -
        name: yesterday - 1
        datetime: 2007-07-26 12:23:34
    -
        name: yesterday
        datetime: 2007-07-27 12:23:34
    -
        name: today
        datetime: 2007-07-28 12:23:34
    -
        name: tommorow
        datetime: 2007-07-29 12:23:34
    -
        name: tomorrow + 1
        datetime: 2007-07-30 12:23:34
--- expected
2007-07-26, yesterday - 1
昨日, yesterday
今日, today
明日, tommorow
2007-07-30, tomorrow + 1

