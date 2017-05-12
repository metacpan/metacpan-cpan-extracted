#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$Petal::BASE_DIR = './t/data/';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;

my $template_file = 'comment_does_not_die.xml';
my $template = new Petal ($template_file);

my $res;
eval { $res = $template->process( bar => 'BAZ' ) };
ok (!$@ => 'process() does not die');
like ($res, qr/<!-- pre><\?error\?><\/pre -->/ => 'comment is the same');


1;


__END__
