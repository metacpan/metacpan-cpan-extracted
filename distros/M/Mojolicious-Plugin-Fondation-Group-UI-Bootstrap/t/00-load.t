#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;
use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use_ok 'Mojolicious::Plugin::Fondation::Group::UI::Bootstrap';

my $meta = Mojolicious::Plugin::Fondation::Group::UI::Bootstrap->fondation_meta;
ok $meta,                       'fondation_meta returns a hashref';
ok $meta->{dependencies},       'has dependencies';
ok $meta->{setup},              'has setup block' if $meta->{setup};

done_testing;
