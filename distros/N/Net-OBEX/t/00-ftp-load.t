#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Carp');
    use_ok('Net::OBEX');
    use_ok('XML::OBEXFTP::FolderListing');
    use_ok('Class::Data::Accessor');
	use_ok( 'Net::OBEX::FTP' );
}

diag( "Testing Net::OBEX::FTP $Net::OBEX::FTP::VERSION, Perl $], $^X" );

use Net::OBEX::FTP;
my $o = Net::OBEX::FTP->new;
isa_ok($o, 'Net::OBEX::FTP');
can_ok($o, qw(        new
        connect
        cwd
        get
        close
        obex
        response
        error
        pwd
        xml
        folders
        files
        _is_success
        _set_error));