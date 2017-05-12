#!/usr/bin/env perl 

use 5.10.0;

use SnipMate::Index;

my $index = SnipMate::Index->new;

$index->generate_pages;

open my $fh, '>', 'index.html';
say $fh $index->render('webpage');
