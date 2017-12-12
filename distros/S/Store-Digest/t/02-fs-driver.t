#!perl

# -*- perl -*-

use DateTime;
use URI;
use Path::Class;
use Test::More tests => 1;

use_ok('Store::Digest::Driver::FileSystem');

my $driver = Store::Digest::Driver::FileSystem->new(dir => 't/content');

my $mf = Path::Class::File->new('Makefile.PL');

my $stat = $mf->stat;

my $fh = $mf->openr;

my $obj = $driver->add(content => $fh, mtime => $stat->mtime);

diag($obj->as_string);

$driver->get(URI->new('ni:///md5;w4bt'));

diag($driver->stats->as_string);
