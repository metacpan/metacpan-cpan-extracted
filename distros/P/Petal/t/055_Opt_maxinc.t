#!/usr/bin/perl
##############################################################################
# Tests the 'max_includes' option to Petal->new.
#

use Test::More tests => 10;

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'if.xml';
my @args     = (
  error => 'Altitude too low!',
);


# Confirm max_includes defaults to 30

my $template = new Petal (file => $file, base_dir => $data_dir);

is($template->max_includes, 30, "max_includes defaults to 30");


# Confirm option can change it

$template = new Petal (file => $file, base_dir => $data_dir, max_includes => 5);

is($template->max_includes, 5, "max_includes option changes it");


# Confirm global also changes it

$Petal::MAX_INCLUDES = 20;
$template = new Petal (file => $file, base_dir => $data_dir);

is($template->max_includes, 20, "\$Petal::MAX_INCLUDES changes it too");


# Confirm option can override changed global

$template = new Petal (file => $file, base_dir => $data_dir, max_includes => 0);

is($template->max_includes, 0, "max_includes option overrides changed global");


=cut

# Check the value passed to included templates

my $options = $template->include_opts;
my $ref = eval "my \$hashref = { $options }";
ok(!$@, "extracted params for included template");

is($ref->{max_includes}, -1, "correct value for max_includes option");

=cut

# Confirm that template with no includes is processed

$@ = '';
$output = eval {
  $template->process(@args);
};
is($@, '', "template with no includes processed successfully");
like($output, qr{^\s*
  <div>\s*
  <p\s+class=.error.\s*>Altitude\stoo\slow!</p>\s*
  </div>
}x, "output is correct");


# Process a template with includes

$data_dir = File::Spec->catdir('t', 'data', 'include');
$file     = 'index_xinclude.xml';
@args     = ();

$template = new Petal (file => $file, base_dir => $data_dir, max_includes => 1, input => 'XML', output => 'XML');

$@ = '';
$output = eval { $template->process(@args) };

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


# Try again but with reduced max_includes setting

$template = new Petal (file => $file, base_dir => $data_dir, max_includes => 0,
input => 'XML', output => 'XML');

$@ = '';
$output = eval { $template->process(@args) };
ok(!$@, "Template with includes successfully processed");
like($output, qr{ERROR:\s+MAX_INCLUDES}x, "Output is correct");

