#!perl

use strict;
use warnings;

use File::Spec;
use File::Path qw( make_path );
use Test::More 'tests' => 11;

use StaticVolt;

my $staticvolt = StaticVolt->new(
    'includes'    => File::Spec->catfile( 't', '_includes' ),
    'layouts'     => File::Spec->catfile( 't', '_layouts' ),
    'source'      => File::Spec->catfile( 't', '_source' ),
    'destination' => File::Spec->catfile( 't', '_site' ),
);
isa_ok $staticvolt, 'StaticVolt';

$staticvolt->compile;

# foo.markdown should be compiled to foo.html
my $foo_file = File::Spec->catfile( 't', '_site', 'foo.html' );
ok -e $foo_file, q{File 'foo.html' exists};

# Analyse the contents of foo.html
open my $fh, '<', $foo_file or die "Error: $!";
my $contents = do { local $/; <$fh> };
ok $contents eq <<'CONTENTS', 'Markdown compiled to HTML';
<p>
<strong>StaticVolt</strong> generates <em>static websites</em>.</p>

<p>Relative base: ./</p>

CONTENTS

# And bar.html
my $bar_file = File::Spec->catfile( 't', '_site', 'subdir1', 'bar.html' );
open $fh, '<', $bar_file or die "Error: $!";
$contents = do { local $/; <$fh> };
is $contents, <<'CONTENTS', 'Subdir Markdown compiled to HTML';
<p>
<strong>StaticVolt</strong> generates <em>static websites</em>.</p>

<p>Relative base: ../</p>

CONTENTS

is $staticvolt->_relative_path ( File::Spec->catfile( 't', '_site', 'file0' ) ),
    './', 'Top dir (level 0)';
is $staticvolt->_relative_path ( File::Spec->catfile( 't', '_site', 'dir1', 'file1' ) ),
    '../', 'subdir (level 1)';
is $staticvolt->_relative_path ( File::Spec->catfile( 't', '_site', 'dir1', 'dir2', 'file2' ) ),
    '../../', 'sub-subdir (level 2)';
is $staticvolt->_relative_path ( File::Spec->catfile( 't', '_site', 'dir1', 'dir2', 'dir3', 'file3' ) ),
    '../../../', 'sub-sub-subdir (level 3)';

# And some tests with a single level _site dir.
$staticvolt = StaticVolt->new(
    'includes'    => File::Spec->catfile( 't', '_includes' ),
    'layouts'     => File::Spec->catfile( 't', '_layouts' ),
    'source'      => File::Spec->catfile( 't', '_source' ),
    'destination' => File::Spec->catfile( '_site' ),
    );
isa_ok $staticvolt, 'StaticVolt';

is $staticvolt->_relative_path ( File::Spec->catfile( '_site', 'file0' ) ),
    './', 'Top dir (level 0)';
is $staticvolt->_relative_path ( File::Spec->catfile( '_site', 'dir1', 'file1' ) ),
    '../', 'subdir (level 1)';
