#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More;
BEGIN {
    eval "use CGI";
    plan skip_all => "CGI required" if $@;
    plan 'no_plan';
}
use Petal;

my $template_file = 'autoload.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
my $template = new Petal ($template_file);

my $res = undef;
eval { $res = $template->process ( cgi => new CGI ) };
ok (!$@);
like ($res => qr/input/);
