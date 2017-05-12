#!perl

use strict;
use warnings;

use File::Spec;
use File::Path qw( make_path );
use Test::More 'tests' => 4;

use StaticVolt;

my $staticvolt = StaticVolt->new(
    'includes'    => File::Spec->catfile( 't', '_includes' ),
    'layouts'     => File::Spec->catfile( 't', '_layouts' ),
    'source'      => File::Spec->catfile( 't', '_source' ),
    'destination' => File::Spec->catfile( 't', '_site' ),
);
isa_ok $staticvolt, 'StaticVolt';

my $qux_dir = File::Spec->catdir( 't', '_site', 'qux' );

make_path $qux_dir;
$staticvolt->compile;

# Check that the qux directory has been removed during compile
ok !-d $qux_dir, q{Directory 'qux' has been removed};

# foo.markdown should be compiled to foo.html
my $foo_file = File::Spec->catfile( 't', '_site', 'foo.html' );
ok -e $foo_file, q{File 'foo.html' exists};

# Analyse the contents of foo.html
open my $fh, '<', $foo_file or die "Error: $!";
my $contents = do { local $/; <$fh> };
is $contents, <<'CONTENTS', 'Markdown compiled to HTML';
<p>
<strong>StaticVolt</strong> generates <em>static websites</em>.</p>

<p>Relative base: ./</p>

CONTENTS
