use strict;
use warnings;
use Test::More tests => 3;

use Directory::Scratch;
use Template::Refine::Fragment;

my $tmp = Directory::Scratch->new;
$tmp->touch('foo.html', '<p>This is HTML.</p>');

my $file = $tmp->exists('foo.html');
ok $file;

my $frag = Template::Refine::Fragment->new_from_file($file);
ok $frag;

is $frag->render, '<p>This is HTML.</p>', 'file read ok';

