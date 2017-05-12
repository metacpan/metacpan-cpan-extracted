#!/usr/bin/perl -w

# This is an example of a working aim client, however, the
# client lacks many of the features which most users will
# be interested in (such as buddy list, etc).

# Usage: ./aim.pl <screen name> <password>

use strict;

use Error qw( :try );
use Net::AIM::TOC::Error;

use Net::AIM::TOC;
use Net::AIM::TOC::Message;

use IO::Socket;

my $screenname = $ARGV[0];
my $password = $ARGV[1];

my $aim;

try { 
	$aim = Net::AIM::TOC->new;

	$aim->connect;
	print "Connected\n";

	$aim->sign_on( $screenname, $password );
	print "Signed on\n";
}
catch Net::AIM::TOC::Error with {
	my $err = shift;
	print $err->text, "\n";
	exit;
};

use IO::Select;
my $read_set = new IO::Select(); # create handle set for reading
$read_set->add( \*STDIN );
$read_set->add( $aim->{_conn}->{_sock} );

my $timeout = 2;

my $buddy = $screenname;

try {
	while (1) {
		my @ready = $read_set->can_read( $timeout );

		foreach my $rh( @ready ) {

			if( $rh == $aim->{_conn}->{_sock} ) {

				try {
					my( $msgObj ) = $aim->recv_from_aol;
					my $msg = $msgObj->getMsg;
					print $msg, "\n";

				}
				catch Net::AIM::TOC::Error with {
					my $err = shift;
					print $err->stringify, "\n";
				};
			}
			else {
				my $line = <$rh>;
				chomp( $line );
	
				# Sending an IM
				if( $line =~ /^\/msg (\w*) (.*)$/ ) {
					$buddy = $1;
					$aim->send_im_to_aol( $1, $2 );
				}
				# Sending a toc command
				elsif( $line =~ /^\/command (toc_.*)$/ ) {
					$aim->send_to_aol( $1 );
				}
				# quit
				elsif( $line =~ /^\/quit/ ) {
					print "Quitting\n";
					$aim->disconnect;
					exit( 0 );
				}
				# Do nothing
				elsif( $line eq '' ) {
					print '';
				}
				# Keep chatting...
				elsif( $line =~ /^(.*)$/ ) {
					$aim->send_im_to_aol( $buddy, $1 );
				}
				else {
					print "Unrecognised command: $line\n";
				};
			};
	    };
	};
}
catch Net::AIM::TOC::Error with {
	my $err = shift;
	print $err->stringify, "\n";
	exit( 1 );
};


