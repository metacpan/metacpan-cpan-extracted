#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::MockModule;
use FindBin qw/$Bin/;
use File::Slurp;
use Net::Google::Code;

my $down_file = "$Bin/sample/10.download.html";

my $download_content = read_file($down_file);
my $mock_downloads = Test::MockModule->new('Net::Google::Code::Download');
$mock_downloads->mock( 'fetch', sub { $download_content } );

my $download = Net::Google::Code::Download->new(
    project => 'net-google-code',
    name    => 'Net-Google-Code-0.01.tar.gz',
);
$download->load;
is( $download->name,  'Net-Google-Code-0.01.tar.gz', 'name is set' );
is( $download->size,  '37.4 KB',                     'size is parsed' );
is( $download->count, 16,                            'count is parsed' );
is( scalar @{ $download->labels }, 2,        'labels number' );
is( $download->labels->[0],        '0.01',   '1st label is parsed' );
is( $download->labels->[1],        'simple', '2nd label is parsed' );
is(
    $download->checksum,
    '5073de2276f916cf5d74d7abfd78a463e15674a1',
    'checksum is parsed'
);
is(
    $download->download_url,
    'http://net-google-code.googlecode.com/files/Net-Google-Code-0.01.tar.gz',
    'download_url is parsed'
);
is( $download->uploaded_by, 'sunnavy', 'uploaded_by is parsed' );
is( $download->uploaded, 'Tue Jan  6 00:16:06 2009', 'uploaded is parsed' );

1;

