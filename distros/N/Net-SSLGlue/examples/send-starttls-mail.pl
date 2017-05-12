use strict;
use warnings;

use Net::SSLGlue::SMTP;
my $smtp = Net::SMTP->new( 'mail.gmx.net', Debug => 1 ) or die $@;
$smtp->starttls( SSL_ca_path => "/etc/ssl/certs" ) or die $@;
$smtp->auth( '123456','password' );
$smtp->mail( 'me@example.org' );
$smtp->to( 'you@example.org' );
$smtp->data;
$smtp->datasend( <<EOD );
From: me
To: you
Subject: test test

lalaal
EOD
$smtp->dataend;
$smtp->quit;

