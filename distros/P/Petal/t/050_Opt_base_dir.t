#!/usr/bin/perl
##############################################################################
# Tests the 'data_dir' option to Petal->new and related functionality.
# Uses t/data/namespaces.xml and t/data/include/index_xinclude.xml
#

use Test::More tests => 16;

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'namespaces.xml';

my @args = (
  replace   => 'Replacement Text',
  content   => 'Content Here',
  attribute => 'An attribute',
  elements  => [ 'one', 'two' ],
);


# Test template not found if path not specified

my $template = new Petal (file => $file);

is_deeply([ $template->base_dir ], [ '.' ],
          "\@Petal::BASE_DIR is used as default base_dir");

$@ = '';
my $output = eval {
  $template->process(@args);
};

ok($@, "Template not found (as expected)");

like($@, qr{
  Cannot\sfind\snamespaces\.xml\sin
}x, "Error message is correct");

# Confirm $Petal::BASE_DIR used as default if defined

{
  local($Petal::BASE_DIR) = 'dummy_dir';

  $template = new Petal (file => $file);
  ok (1);
#  is_deeply([ $template->base_dir ], [ 'dummy_dir', '.' ], 
#            "\$Petal::BASE_DIR is in default base_dir");

  $@ = '';
  $output = eval {
    $template->process(@args);
  };

  ok($@, "Template still not found (as expected)");
  like($@, qr{
    Cannot\sfind\snamespaces\.xml\sin
  }x, "Error message is correct");
}


# Confirm base_dir option as arrayref works

$template = new Petal (file => $file, base_dir => ['dummy1', 'dummy2']);

is_deeply([ $template->base_dir ], [ 'dummy1', 'dummy2' ], 
          "base_dir option specified as arrayref works");

$@ = '';
$output = eval {
  $template->process(@args);
};

ok($@, "Template still not found (as expected)");
like($@, qr{
  Cannot\sfind\snamespaces\.xml\sin
}x, "Error message is correct");


# Confirm base_dir option as scalar works

$template = new Petal (file => $file, base_dir => 'dummy');

is_deeply([ $template->base_dir ], [ 'dummy' ], 
          "base_dir option specified as scalar works");

$@ = '';
$output = eval {
  $template->process(@args);
};

ok($@, "Template still not found (as expected)");
like($@, qr{
  Cannot\sfind\snamespaces\.xml\sin
}x, "Error message is correct");


# Now specify a valid base_dir option and process a template

$template = new Petal (file => $file, base_dir => $data_dir);

$@ = '';
$output = eval {
  $template->process(@args);
};

ok(!$@, "Template was found");
like($output, qr{^\s*
  <body\s*>\s+
  Replacement\sText\s+
  <p\s*>Content\sHere</p>\s+
  <p\s+attribute=(['"])An\sattribute\1\s*>yo</p>\s+
  <ul>\s*
  <li>one</li>\s*
  <li>two</li>\s*
  </ul>\s+
  </body>
}x, "Output is correct");


# Try processing a template with an include (data_dir is required for included
# template too).

$data_dir = File::Spec->catdir('t', 'data', 'include');
$file     = 'index_xinclude.xml';

$template = new Petal (file => $file, base_dir => $data_dir);

$@ = '';
$output = eval {
  $template->process(@args);
};

ok(!$@, "Template with includes successfully processed");
like($output, qr{^\s*
  <xml>\s+
  <div>\s+
  <p>__INCLUDED__</p>\s+
  <p>__INCLUDED__</p>\s+
  <p></p>\s+
  </div>\s+
  </xml>
}x, "Output is correct");

