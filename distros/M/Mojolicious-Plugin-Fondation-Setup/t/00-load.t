#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use_ok 'Mojolicious::Plugin::Fondation::Setup';

my $meta = Mojolicious::Plugin::Fondation::Setup->fondation_meta;
ok $meta,                 'fondation_meta returns a hashref';
ok $meta->{dependencies}, 'has dependencies';

done_testing;
