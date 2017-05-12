#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::JSON;

use JSON;
use StatusBoard::Graph;
use StatusBoard::Graph::DataSeq;

my $expected_data = {
    graph => {
        title => "Soft Drink Sales",
        datasequences => [
            {
                title => "X-Cola",
                datapoints => [
                    { "title" => "2008", "value" => 22 },
                    { "title" => "2009", "value" => 24 },
                    { "title" => "2010", "value" => 25.5 },
                    { "title" => "2011", "value" => 27.9 },
                    { "title" => "2012", "value" => 31 },
                ]
            },
            {
                "title" => "Y-Cola",
                "datapoints" => [
                    { "title" => "2008", "value" => 18.4 },
                    { "title" => "2009", "value" => 20.1 },
                    { "title" => "2010", "value" => 24.8 },
                    { "title" => "2011", "value" => 26.1 },
                    { "title" => "2012", "value" => 29 },
                ]
            },
        ]
    }
};

my $expected_pretty_json = to_json(
    $expected_data,
    {
        pretty => 1,
    },
);

my $sg = StatusBoard::Graph->new();
$sg->set_title("Soft Drink Sales");

my $ds1 = StatusBoard::Graph::DataSeq->new();
$ds1->set_title("X-Cola");
$ds1->set_values(
    [
        2008 => 22,
        2009 => 24,
        2010 => 25.5,
        2011 => 27.9,
        2012 => 31,
    ]
);

$sg->add_data_seq($ds1);

my $ds2 = StatusBoard::Graph::DataSeq->new();
$ds2->set_title("Y-Cola");
$ds2->set_values(
    [
        2008 => 18.4,
        2009 => 20.1,
        2010 => 24.8,
        2011 => 26.1,
        2012 => 29,
    ]
);

$sg->add_data_seq($ds2);

is_json(
    $sg->get_pretty_json(),
    $expected_pretty_json,
    'StatusBoard::Graph basic usage',
);

done_testing;
