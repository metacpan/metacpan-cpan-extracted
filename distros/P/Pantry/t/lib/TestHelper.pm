use 5.010;
use strict;
use warnings;
package TestHelper;

use parent 'Exporter';
our @EXPORT = qw(
  _thaw_file
  _dump_node
  _try_command
  _create_pantry
  _create_node
);

use App::Cmd::Tester::CaptureExternal;
use File::Slurp qw/read_file/;
use File::pushd 1.00 qw/tempd/;
use JSON;
use Test::More;
use Pantry::App;
use Pantry::Model::Pantry;

sub _thaw_file {
  my $file = shift;
  my $guts = scalar read_file( $file );
  my $data = eval { decode_json( $guts ) };
  die if $@;
  return $data;
}

sub _dump_node {
  my $node = shift;
  my $path = $node->path;
  diag "File contents of " . $node->name . ":\n" . join("", explain _thaw_file($path));
}

sub _try_command {
  my @command = @_;
  my $opts = {
    exit_code => 0,
  };
  if ( ref $command[-1] eq 'HASH' ) {
    $opts = pop @command;
  }
  pop @command unless length $command[-1];

  my $result = test_app( 'Pantry::App' => [@command] );
  is( $result->exit_code, $opts->{exit_code}, "'pantry @command' exit code" )
    or diag $result->output || $result->error;
  return $result;
}

sub _create_pantry {
  my $wd = tempd;
  _try_command(qw(init));
  my $pantry = Pantry::Model::Pantry->new( path => "$wd" );
  return ($wd, $pantry);
}

sub _create_node {
  my ($name) = @_;
  $name //= 'foo.example.com';
  my ($wd, $pantry) = _create_pantry;

  _try_command(qw(create node), $name);

  my $node = $pantry->node($name);
  if ( -e $node->path ) {
    pass("test node file found");
  }
  else {
    fail("test node file found");
    diag("node $name not found at " . $node->path);
    diag("bailing out of rest of the subtest");
    return;
  }

  return ($wd, $pantry);
}


1;

