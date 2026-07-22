use strict;
use warnings;

use lib qw{ . lib };

use Test::More;
use File::Temp qw( tempfile );

plan tests => 6;

use_ok qw( Module::ScanDeps::Static );

# --- shared fixtures -------------------------------------------------

my ( $fh, $path ) = tempfile( SUFFIX => '.pm.in', UNLINK => 1 );
print {$fh} "package Foo;\nuse CGI;\nuse Carp;\n1;\n";
close $fh;

my $CODE = "package Bar;\nuse Carp;\n1;\n";

########################################################################
subtest 'multi-word underscore-style keys are recognized' => sub {
########################################################################
  # bug: the shim built "--$key" with no underscore-to-dash
  # translation, so "min_core_version" never matched the
  # "min-core-version" option_spec and GetOptions rejected it outright.

  my $scanner = Module::ScanDeps::Static->new(
    { path => $path, core => 0, min_core_version => '5.30.0' } );

  is( $scanner->get_min_core_version, '5.30.0',
    'underscore-style multi-word key reaches the object correctly' );
};

########################################################################
subtest 'negatable boolean options respect an explicit false value' => sub {
########################################################################
  # bug: every key was pushed onto @argv as "--$key $value", but a
  # negatable spec (e.g. core|c!) doesn't take a value -- "--core 0"
  # sets core TRUE and leaves a stray "0" as a positional argument.

  my $off = Module::ScanDeps::Static->new( { path => $path, core => 0 } );
  is( $off->get_core, 0, 'core => 0 correctly sets core false' );

  my $on = Module::ScanDeps::Static->new( { path => $path, core => 1 } );
  is( $on->get_core, 1, 'core => 1 correctly sets core true' );
};

########################################################################
subtest 'plain boolean options (no negated form) handle false safely'
  => sub {
########################################################################
  # bug: some specs (json|j, raw|r, text|t...) have no "!" and
  # therefore no --no-X form at all. Treating them like negatable
  # options would emit a flag GetOptions doesn't recognize.

  my $off = Module::ScanDeps::Static->new( { path => $path, json => 0 } );
  ok( !$off->get_json, 'json => 0 is handled without error (flag omitted)' );

  my $on = Module::ScanDeps::Static->new( { path => $path, json => 1 } );
  ok( $on->get_json, 'json => 1 correctly sets json true' );
};

########################################################################
subtest 'extra_options fields (handle) bypass GetOptions entirely' => sub {
########################################################################
  # bug: `handle` is declared in extra_options, not option_specs --
  # it can never be a real command-line flag (a filehandle isn't a
  # string), so pushing "--handle $fh" onto @argv always failed.

  open my $data_fh, '<', \$CODE or die $!;

  my $scanner
    = Module::ScanDeps::Static->new( { handle => $data_fh, core => 0 } );

  is( $scanner->get_handle, $data_fh,
    'handle passed via hashref reaches the object unchanged' );

  my @deps = $scanner->parse;

  ok( ( grep {/Carp/xsm} @deps ), 'parse() actually works against it' )
    or diag( explain \@deps );
};

########################################################################
subtest 'mixed call exercises all categories together' => sub {
########################################################################
  open my $data_fh, '<', \$CODE or die $!;

  my $scanner = Module::ScanDeps::Static->new(
    {
      path             => $path,
      core             => 0,
      min_core_version => '5.30.0',
      add_version      => 1,
      handle           => $data_fh,
    }
  );

  is( $scanner->get_path,             $path,     'path' );
  is( $scanner->get_core,             0,         'core (negatable false)' );
  is( $scanner->get_min_core_version, '5.30.0',  'min_core_version (underscore key)' );
  is( $scanner->get_add_version,      1,         'add_version (negatable true)' );
  is( $scanner->get_handle,           $data_fh,  'handle (extra_options)' );
};

1;
