#! /usr/bin/perl

use strict;
use warnings;
use Selenium::Screenshot;
use Selenium::Remote::Driver;

my $d = Selenium::Remote::Driver->new(
    browser_name => 'chrome',
    default_finder => 'css'
);
$d->set_window_size(480, 640);

$d->get('http://www.google.com');

my @elems = $d->find_elements('p');
my @exclude = map {
    my $rect = {
        size => $_->get_size,
        location => $_->get_element_location
    };
    $rect
} @elems;

my $s = Selenium::Screenshot->new(
    png => $d->screenshot,
    exclude => [ @exclude ],
);

$d->get('http://www.yahoo.com');
my $t = Selenium::Screenshot->new(png => $d->screenshot);

print $s->compare($t);
system('open', $s->difference($t));
