#!/usr/bin/perl
##############################################################################
# Tests the 'language' option (and 'lang' alias) to Petal->new.
# Uses t/data/language/*
#

# this is identical to t/052_Opt_language but with DISK_CACHE=1

use Test::More 'no_plan';

use warnings;
use lib 'lib';

use Petal;
use File::Spec;

$Petal::DISK_CACHE   = 1;
$Petal::MEMORY_CACHE = 0;

my $data_dir = File::Spec->catdir('t', 'data');
my $file     = 'language';

my @args = (
  replace   => 'Replacement Text',
  content   => 'Content Here',
  attribute => 'An attribute',
  elements  => [ 'one', 'two' ],
);


# Try processing a template with a language and an include

my $template = new Petal (file => $file, base_dir => $data_dir, language => 'fr');

is($template->language, 'fr', 'correct language requested (fr)');

$@ = '';
$output = eval { $template->process(@args) };

ok(!$@, "template with language and includes successfully processed");
like($output, qr{^\s*
  <p>\s+
  <span>Bonjour,\sMonde\s\(fr\)</span>\s+
  </p>
}x, "output is correct");


# Same again but using 'lang' option alias

$template = new Petal (file => $file, base_dir => $data_dir, lang => 'fr-CA');

is($template->language, 'fr-CA', 'correct language requested (fr-CA)');

$@ = '';
$output = eval { $template->process(@args) };

ok(!$@, "template with lang and includes successfully processed");
like($output, qr{^\s*
  <p>\s+
  <span>Bonjour,\sMonde\s\(fr-CA\)</span>\s+
  </p>
}x, "output is correct");
