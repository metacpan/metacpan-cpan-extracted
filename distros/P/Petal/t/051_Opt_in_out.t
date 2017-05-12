#!/usr/bin/perl
##############################################################################
# Tests the 'input' and 'output' options to Petal->new and related
# functionality.  Uses t/data/if.html and t/data/if.xml for templates.
# 'if.html' is assumed to not be well formed.
#

use Test::More tests => 3;

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

$Petal::DISK_CACHE = 0;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'if.html';

my @args = (
  error => 'Altitude too low!',
);


# Confirm input format defaults to XML
my $template = new Petal (file => $file, base_dir => $data_dir);

# is($template->input, 'XML', "input format defaults to 'XML'");

$@ = '';
my $output = eval {
  $template->process(@args);
};

# ok($@, "Template processing fails (as expected)");


# Confirm that it works with something that's good enough
$template = new Petal (file => 'if.xml', base_dir => $data_dir, input => 'HTML');
is ($template->input, 'HTML', "input option overrides default");

$@ = '';
$output = eval {
  $template->process(@args);
};

ok (!$@, "Template processed successfully");
like ($output, qr{^\s*
  <div>\s*
  <p\s+class=.error.\s*>Altitude\stoo\slow!</p>\s*
  </div>
}x, "Output is correct");



