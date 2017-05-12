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

my $template_file = 'basic.xml';
my $template = new Petal ($template_file);


my $hash = {
    loop => [''],
};

my $string = $template->process ($hash);
like ($string => qr /REPLACE/);
like ($string => qr /CONTENT/);
like ($string => qr /CONDITION/);
like ($string => qr /LOOP/);
unlike ($string => qr /OMIT-ME/);
like ($string => qr /<a foo-bar="baz">/);


1;


__END__
