#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('Carp');
    use_ok('POE');
    use_ok('POE::Component::Net::FTP');
    use_ok('POE::Component::IRC::Plugin');
    use_ok('Devel::TakeHashArgs');
	use_ok( 'POE::Component::IRC::Plugin::FTP::EasyUpload' );
}

diag( "Testing POE::Component::IRC::Plugin::FTP::EasyUpload $POE::Component::IRC::Plugin::FTP::EasyUpload::VERSION, Perl $], $^X" );
