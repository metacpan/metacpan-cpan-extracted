#!/usr/bin/env perl

use 5.010;
use lib qw(lib);

use Posterous;
use Data::Dumper;
use YAML qw(LoadFile);

$config = LoadFile("$ENV{HOME}/.posterous");

$posterous = Posterous->new($config->{core}->{user}, $config->{core}->{pass});

say Dumper $posterous->read_posts;

say Dumper $posterous->read_public_posts( site_id => 304643 );
