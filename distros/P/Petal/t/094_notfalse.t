#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $template_file = 'notfalse.xml';
my $template      = new Petal ($template_file);
my $string        = $template->process (always_false => 0, always_true => 1);

like ($string, qr/A/,   'test A');
unlike ($string, qr/B/,       'test B');
like ($string, qr/C/,   'test C');
unlike ($string, qr/D/,       'test D');
unlike ($string, qr/E/,       'test E');
like ($string, qr/F/,   'test F');
unlike ($string, qr/G/,       'test G');
like ($string, qr/H/,   'test H');

__END__
