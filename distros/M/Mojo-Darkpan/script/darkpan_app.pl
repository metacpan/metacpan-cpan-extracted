#!/usr/bin/env perl
use v5.20;
use strict;
use warnings;
use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('local/lib')->to_string;
use Mojolicious::Commands;

Mojolicious::Commands->start_app('Mojo::Darkpan');