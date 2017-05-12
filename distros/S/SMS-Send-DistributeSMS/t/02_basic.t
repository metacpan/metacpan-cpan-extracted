#!/usr/bin/perl -w

# Try to make sure the website is actually there

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 6;
use SMS::Send;

sub dies_like {
	my ($code, $regexp) = (shift, shift);
	eval { &$code() };
	like( $@, $regexp, $_[0] || "Dies as expected with message like $regexp" );
}

#####################################################################
# Test as many errors as we can without hitting the web

#dies_like(
#	sub { SMS::Send->new( 'DistributeSMS',
#		_account_no  => '1234',
#		_password    => 'password',
#		) },
#	qr/no login specified/,
#);

#####################################################################
# Testing up to the point of a working login

# Create a new sender
my $sender = SMS::Send->new( 'DistributeSMS',
		_account_no  => '1234',
		_login       => 'login',
		_password    => 'password',
	);
isa_ok( $sender, 'SMS::Send' );

# Test some internals
isa_ok( $sender->_OBJECT_, 'SMS::Send::DistributeSMS' );
is( $sender->_OBJECT_->{account_no},    '1234',
	'Account number set correctly in internals' );
is( $sender->_OBJECT_->{login}, 'login',
	'Login set correctly in internals' );
is( $sender->_OBJECT_->{password}, 'password',
	'Password set correctly in internals' );


#####################################################################
# More failures with an actual account

dies_like(
	sub { $sender->_OBJECT_->_login },
	qr/login: could not log in/,
);

exit(0);
