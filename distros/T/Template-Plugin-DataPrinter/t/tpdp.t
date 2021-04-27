#!/usr/bin/env perl

use lib './t/lib';
use Template::Plugin::DataPrinter::TestUtils;

use Test::More;
require Test::NoWarnings;

use File::Temp      ();
use HTML::Entities  qw< encode_entities >;
use Term::ANSIColor qw< color >;

delete $ENV{DATAPRINTERRC}; # make sure user rc doesn't interfere

# Use some custom settings in the header. This lets us test some extra stuff
# 1. we can be sure to expect these type/color combinations
# 2. check that the dp and hfat parameters are honored
my $template_header = <<'EOT';
USE DataPrinter(
    dp   = { colors = { string='blue', number='cyan' } },
    hfat = { class_prefix = 'test_' },
);
EOT

my %stash = (
    string => 'a <div> string', # include html tag to make sure it gets escaped
    number => 1234,
    code   => sub { $_[0] + $_[1] },
);

{
    note 'Testing dump';

    my $template = "[%
        $template_header
        DataPrinter.dump(string, number);
    %]";

    my $ansi = process_ok($template, \%stash, 'dump template processed ok');

    my $blue  = quotemeta(color('blue'));
    my $cyan  = quotemeta(color('cyan'));
    my $reset = quotemeta(color('reset'));
    like($ansi, qr/$blue.*$stash{string}.*$reset/,
        'output contains blue string');
    like($ansi, qr/$cyan.*$stash{number}.*$reset/,
        'output contains cyan number');
    like($ansi, qr/$stash{string}.*$stash{number}/s,
        'output contains string and number in correct order');
}

{
    note 'Testing dump_html';

    my $template = "[%
        $template_header
        DataPrinter.dump_html(string, number);
    %]";

    my $html = process_ok($template, \%stash,
        'dump_html template processed ok');

    my %estash = map { $_ => encode_entities($stash{$_}) } keys %stash;

    like($html, qr/test_blue.*$estash{string}/s, 'output contains blue string');
    like($html, qr/test_cyan.*$estash{number}/s, 'output contains cyan number');
    like($html, qr/$estash{string}.*$estash{number}/s,
        'output contains string in number in correct order');
}

{
    note 'Testing dump_html css';

    my $template = "[%
        $template_header
        DataPrinter.dump_html(string);
        DataPrinter.dump_html(number);
    %]";

    my $html = process_ok($template, \%stash,
        'dump_html template processed ok');

    match_count_is($html, qr/<style/, 1, 'css is output only once');

    my %estash = map { $_ => encode_entities($stash{$_}) } keys %stash;

    like($html, qr/test_blue.*$estash{string}/s, 'output contains blue string');
    like($html, qr/test_cyan.*$estash{number}/s, 'output contains cyan number');
}

{
    note 'Testing Dumper dropin replacement operation for dump';

    my $template0 = '[%
        USE Dumper;
        Dumper.dump(string, number);
    %]';

    my $template1 = $template0;
    $template1 =~ s/Dumper/DataPrinter/g;

    my $tt = Template->new(PLUGINS => {
        Dumper => 'Template::Plugin::DataPrinter'
    });

    templates_match($template0, $template1, \%stash,
        'Dumper alias works', $tt);
}


{
    note 'Testing Dumper dropin replacement operation for dump_html';

    my $template0 = '[%
        USE Dumper;
        Dumper.dump_html(string, number);
    %]';

    my $template1 = $template0;
    $template1 =~ s/Dumper/DataPrinter/g;

    my $tt = Template->new(PLUGINS => {
        Dumper => 'Template::Plugin::DataPrinter'
    });

    my $out0 = process_ok($template0, \%stash, 'template0', $tt);
    my $out1 = process_ok($template1, \%stash, 'template1', $tt);

    TODO: {
        local $TODO = 'Spurious css ordering mismatches in 5.18'
            if $] >= 5.018;

        is($out0, $out1, 'HTML dumps match exactly');
    }

    # Strip the css lines and make sure the rest matches
    $out0 =~ s{<style.*/style>}{}mi;
    $out1 =~ s{<style.*/style>}{}mi;

    is($out0, $out1, 'HTML dumps without css match exactly');
}

Test::NoWarnings::had_no_warnings();
done_testing;
