#!perl

use Test::Most;

use Path::Tiny;
use Template;

my $engine = Template->new();

subtest scalar => sub {

    my $var = "/foo/bar//baz";

    foreach my $method (qw/ parent basename canonpath /) {

        my $template = "[% USE Path::Tiny; x.as_path.${method} %]";

        ok $engine->process( \$template, { x => $var }, \my $output ),
          "process ${template}"
          or diag $engine->error();

        my $path = path($var);

        is $output => $path->$method, $method;

    }

};

subtest list => sub {

    my @var = qw( foo bar baz );

    foreach my $method (qw/ parent basename canonpath /) {

        my $path = path(@var);

        my $template = "[% USE Path::Tiny; x.as_path.${method} %]";

        ok $engine->process( \$template, { x => \@var }, \my $output ),
          "process ${template}"
          or diag $engine->error();

        is $output => $path->$method, $method;

        note "$path";

        note $output;
    }

};

done_testing;
