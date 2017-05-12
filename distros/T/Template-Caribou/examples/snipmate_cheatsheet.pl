#!/usr/bin/env perl 

use 5.10.0;

use SnipMate::Snippets;

say SnipMate::Snippets->new( snippet_file => shift )->render('webpage');
