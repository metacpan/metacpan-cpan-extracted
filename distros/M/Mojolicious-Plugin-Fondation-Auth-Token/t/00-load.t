#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;

use_ok('Mojolicious::Plugin::Fondation::Auth::Token');
use_ok('Mojolicious::Plugin::Fondation::Auth::Token::Schema::Result::ApiToken');

done_testing;
