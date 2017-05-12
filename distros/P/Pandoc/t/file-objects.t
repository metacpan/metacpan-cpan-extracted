use strict;
use Test::More;
use Test::Exception;
use Pandoc;

use subs qw(path tempdir);

plan skip_all => 'pandoc executable required' unless pandoc;
plan skip_all => 'Path::Tiny required'
    unless eval 'use Path::Tiny qw(path tempdir); 1;';

my $dir = tempdir( CLEANUP => 1 );

(my $input = $dir->child('input.md'))->spew_utf8(<<'DUMMY_TEXT');
## Eius Ut

Qui aut voluptate minima.
DUMMY_TEXT
note $input->slurp_utf8;

my $output = $dir->child('output.html');

lives_ok { pandoc->run(-o => $output, $input) } 'call pandoc with file objects as arguments';
note $output->slurp_utf8;

done_testing;
