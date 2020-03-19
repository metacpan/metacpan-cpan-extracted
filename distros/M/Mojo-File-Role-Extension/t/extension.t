# -*- mode: perl; -*-
use Mojo::Base -strict;
use Test::More;
use Mojo::File 'path';
use Role::Tiny ();

my $file;

# apply role
$file = path '/tmp/preferred-name.ext';
$file->with_roles('+Extension');
is Role::Tiny::does_role($file, 'Mojo::File::Role::Extension'), 1,
    'role applied';

$file = Mojo::File->with_roles('+Extension')->new('/tmp/preferred-name.ext');
is Role::Tiny::does_role($file, 'Mojo::File::Role::Extension'), 1,
    'role applied';
    
# moniker and extension
is $file->moniker, 'preferred-name', 'correct short name';
is $file->extension, '.ext', 'correct extension';
is_deeply $file->extension_parts, ['.ext'], 'collection';

# directory
$file = path('/etc/directory.d/')->with_roles('+Extension');
is $file->moniker, 'directory', 'directories have suffices too';
is $file->extension, '.d', 'extension';
is_deeply $file->extension_parts, ['.d'], 'collection';

# change extension - new Mojo::File object
$file = path('./Mojo-File-Role-Extension-0_1.tar')->with_roles('+Extension');
my $no_ext = $file->switch_extension;
is $no_ext->extension, '', 'empty';
is $no_ext, './Mojo-File-Role-Extension-0_1', 'full name';
my $tar_gz = $file->switch_extension('.tar.gz');
is $tar_gz->extension, '.tar.gz', 'correct extension';
is $no_ext->switch_extension('.tar.gz'), $tar_gz, 'same';

# paths with multiple '.' as a collection
$file = path('/tmp/alignments.genome.unsorted.bam')->with_roles('+Extension');
is $file->moniker, 'alignments';
my $parts = $file->extension_parts;
is $parts->size, 3, 'correct no of parts';
is_deeply $parts, ['.genome', '.unsorted', '.bam'], 'collection';
is $file->switch_extension($parts->tap(sub { $_->[1] = '.sorted' })->join),
  '/tmp/alignments.genome.sorted.bam', 'sorted version';

done_testing;
