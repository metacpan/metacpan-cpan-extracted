# -*- mode: perl; -*-

use strict;
use warnings;
use Test::More;
use Mojo::Path;

my $path = Mojo::Path->with_roles('+Relative')->new('/path/to/files/AX1113');

my $base = Mojo::Path->new('/path/to/files');
isa_ok $path->to_rel($base), 'Mojo::Path', 'correct object type';
is $path->to_rel($base), 'AX1113', 'correct rel';
is $path->to_subpath_of($base), 'AX1113', 'correct subpath';

is $path->to_rel('/path/to/files'), 'AX1113', 'correct rel';
is $path->to_subpath_of('/path/to/files'), 'AX1113', 'correct subpath';

$base = Mojo::Path->new('/path/to/');
is $path->to_rel($base), 'files/AX1113', 'correct rel';
is $path->to_subpath_of($base), 'files/AX1113', 'correct subpath';
is $path->is_subpath_of($base), 1, 'yes';

$base = Mojo::Path->new('/new-path/to/files');
is $path->to_rel($base), '../../../path/to/files/AX1113', 'relative with ..';
is $path->to_subpath_of($base), '/path/to/files/AX1113', '? subdir';
is $path->is_subpath_of($base), '', 'no';

done_testing;
