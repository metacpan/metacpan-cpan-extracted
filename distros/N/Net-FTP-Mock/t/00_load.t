#!/usr/bin/perl

use strict;
use warnings;

package load_test;

use Test::Most;

use lib '../lib';
use lib 'lib';

use_ok(
    "Net::FTP::Mock",
    localhost => {
        username => { password => {
            active => 1,
            root => "t/remote_ftp/"
        }},
    },
    'ftp.work.com' => {
        harry => { god => {
            active => 1,
            root => "t/other_remote_ftp/"
        }},
    },
);

my $ftp = Net::FTP->new("ftp.work.com", Debug => 0);
isa_ok( $ftp, 'Net::FTP' );
ok( $ftp->login( "harry",'god' ), 'logging into a prepared account works' );
ok( !$ftp->quit, 'quitting works' );

done_testing;
