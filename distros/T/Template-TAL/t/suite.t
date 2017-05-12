#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 36;
use FindBin qw( $Bin );
use File::Spec::Functions;
use Test::XML;

# this is probably the most comprehensive test - there are files in t/tests/*,
# of the form *.tal and *.out - we verify that every tal file parses to the
# contents of the .out file.


use Template::TAL;

package MyObject;
sub list { return [1,2,3] }
sub hash { return { one => 1, two => 2, three => 3 } }
sub scalar { return 'a string' }
package main;

# all templates get the same test data
my $data = {
  title => "some title",
  colours => [ 'red', 'green', 'blue' ],
  test_true => 1,
  test_false => 0,
  deep => {
    foo => 1,
    bar => 2,
    baz => 3,
  },
  object => bless( {}, "MyObject"),
  html => '<p>this is html</p>',
  utf8 => "this string contains an e-acute: \x{e9}",
};

run_tests('tests');

TODO: {
  run_tests('todo', "todo tests");
}

sub run_tests {
  my $folder = shift;
  my $todo = shift;
  
  ok( my $tt = Template::TAL->new(
    include_path => [ catdir($Bin, $folder) ],
    output => "Template::TAL::Output::XML",
  ), "got tt");
  
  # read all tests from the test suite folder
  ok( opendir(TESTS, catdir($Bin, $folder)), "opened '$folder' folder" );
  my @tests = grep { !/^\./ } grep { s/\.tal$// } readdir(TESTS);
  ok(@tests, "have ".~~@tests." '$folder' tests");

  local $TODO = $todo;  
  for my $test (@tests) {
    my $expected = slurp(catfile($Bin, $folder, "${test}.out"))
    or die "no output file for test $test";
    my $output = eval { $tt->process("${test}.tal", $data) }; diag($@) if $@;
    ok(!$@, "no errors from process");
    is_xml($output || "", $expected, "test '$test' passed");
  }
}

#########################
sub slurp {
  open READ, $_[0] or die "can't read $_[0]: $!";
  local $/;
  return <READ>;
}
  
