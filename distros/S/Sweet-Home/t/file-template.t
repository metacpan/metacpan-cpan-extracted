use strict;
use warnings;

use Test::More tests => 2;

use File::Temp qw(tempdir);
use Sweet::Dir;
use Sweet::File::Template;

my $test_dir = Sweet::Dir->new(path => 't');

my $temp_path = tempdir();
my $temp_dir = Sweet::Dir->new(path => $temp_path)->create;

my $template1 = Sweet::File::Template->new(
    name          => 'template1.txt',
    dir           => $temp_dir,
    include_path  => $test_dir->path,
    template_name => 'template1.tt2',
    template_vars => { foo => 'bar' },
);

$template1->generate;
ok $template1->is_a_plain_file, 'generate';

is $template1->output, "this is a template\nbar", 'output';

