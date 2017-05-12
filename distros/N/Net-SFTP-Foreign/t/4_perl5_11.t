#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib "./t";
use common;

plan skip_all => "tests not supported on inferior OS"
    if (is_windows and eval "no warnings; getlogin ne 'salva'");

my @new_args = new_args;

plan tests => 2;

use Net::SFTP::Foreign;

my $sftp = Net::SFTP::Foreign->new(@new_args);
my $fn = File::Spec->rel2abs('t/data.txd');

ok(my $fh = $sftp->open($fn), "open");
ok (!eof($fh), "eof");
