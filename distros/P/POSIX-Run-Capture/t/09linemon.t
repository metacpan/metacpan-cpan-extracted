# -*- perl -*-

use lib 't', 'lib';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 3;

our($catbin, $input, $content);

my @lines;

TestCapture({ argv => [$catbin, $input],
              stdout => sub { push @lines, shift } });

is($content, join('', @lines));

@lines = ();

TestCapture({ argv => [$catbin, '-l', 31, $input],
              stdout => sub { push @lines, shift } });

is_deeply(\@lines, ['CHAPTER I. Down the Rabbit-Hole']);

@lines = ();

TestCapture({ argv => [$catbin, '-l', 102, $input],
              stdout => sub { push @lines, shift } });

is_deeply(\@lines, [ "CHAPTER I. Down the Rabbit-Hole\n",
		     "\n",
		     'Alice was beginning to get very tired of sitting by her sister on the' ]);

    
