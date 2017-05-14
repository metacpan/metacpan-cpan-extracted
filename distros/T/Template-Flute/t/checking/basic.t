#!perl
use strict;
use warnings;

use utf8;

use Test::More tests => 9;
use Test::Deep;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Template::Flute;
use Data::Dumper;

my $bad_spec =<<'SPEC';
<specification>
<value name="cammmmmel" />
</specification>
SPEC

my $html =<< 'HTML';
<!doctype html>
<head></head>
<html>
<div class="camel">
</html>
HTML

my $good_spec = <<'SPEC';
<specification>
<value name="camel" />
</specification>
SPEC

my %values = (
              camelll => 'ラクダ',
             );

my $flute;

$flute = Template::Flute->new(template => $html,
                              specification => $bad_spec,
                              values => \%values);


my @empty = $flute->specification->dangling;
# diag Dumper(\@empty);
ok(@empty, "Found empty elements");
cmp_deeply @empty, ({
                     'dump' => {name => 'cammmmmel',
                                type => 'value',
                            },
                     'name' => 'cammmmmel',
                     'type' => 'class'
                    })
                   , "Report ok";


foreach my $internal (qw/_ids _classes _names/) {
    ok $flute->specification->can($internal), "Can do $internal";
}


$Data::Dumper::Maxdepth = 5;
ok(!$flute->specification->elements_by_class("camel"));
ok($flute->specification->elements_by_class("cammmmmel"));

$flute = Template::Flute->new(template => $html,
                              specification => $good_spec,
                              values => \%values);

@empty = $flute->specification->dangling;
ok(!@empty, "No empty elements found");


ok($flute->specification->elements_by_class("camel"));


