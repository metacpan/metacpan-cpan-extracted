#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use FindBin qw($Bin);

use lib "$Bin/../lib";

use SMB::File;

my $dir = SMB::File->new(share_root => "$Bin/../shares/test", name => "");
isa_ok($dir, 'SMB::File');
ok($dir->exists, "Dir exists ($dir->{filename})");
like($dir->filename, qr{/test$}, "full filename includes name");
unlike($dir->filename, qw{/\.\./}, "full filename is normalized");

my $files = $dir->find_files;
my $num1 = @$files;
isnt($num1, 0, "Non-empty list of sub-files");
isa_ok($files->[0], 'SMB::File');
is($files->[0]->name, '.', 'First file name is dot');

$files = $dir->find_files(pattern => 'no-such-name');
is(scalar @$files, 0, "Empty list of sub-files");

$files = $dir->find_files(pattern => '*e*', start_idx => 1);
my $num2 = @$files;
isnt($num2, 0, "Non-empty list of sub-files");
isnt($num2, $num1, "Different list of files");
isa_ok($files->[0], 'SMB::File');

$files = $dir->find_files;
my $num3 = @$files;
isnt($num3, 0, "Non-empty list of sub-files");
is($num3, $num1, "Same list of files");
isa_ok($files->[0], 'SMB::File');
is($files->[1]->name, '..', 'Second file name is dot-dot');

