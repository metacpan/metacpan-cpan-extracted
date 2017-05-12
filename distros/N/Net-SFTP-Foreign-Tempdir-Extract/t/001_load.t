# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 5;

BEGIN { use_ok( 'Net::SFTP::Foreign::Tempdir::Extract' ); }
BEGIN { use_ok( 'Net::SFTP::Foreign::Tempdir::Extract::File' ); }

my $sftp = Net::SFTP::Foreign::Tempdir::Extract->new;
isa_ok ($sftp, 'Net::SFTP::Foreign::Tempdir::Extract');

my $file = Net::SFTP::Foreign::Tempdir::Extract::File->new("/tmp");
isa_ok($file, 'Net::SFTP::Foreign::Tempdir::Extract::File');
isa_ok($file, 'Path::Class::File');

