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

my $template_file = 'eval.xml';
my $template      = new Petal ($template_file);
my $string        = $template->process;

like( $string, qr/should\s+appear/, 'should appear (XML out)' );
like( $string, qr/booo/,            'booo (XML out)' );
unlike( $string, qr/should\s+not\s+appear/, 'should not appear (XML out)' );

__END__
