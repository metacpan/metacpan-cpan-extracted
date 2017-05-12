#!/usr/local/bin/perl

use strict;
use Parse::Tokens;

my $input;
while(<>) { $input .= $_; }

my $parser = new Parse::Tokens ({
	token_callback => \&mytoken,
	ether_callback => \&mytext,
	text => $input,
	delimiters => [['<?','?>']],
});

$parser->parse();

# which could also be accompolished in a single statement
#Parse::Tokens->new->parse ({
#	token_callback => \&foo,
#	ether_callback => \&bar,
#	text => $input,
#	delimiters => [['<?','?>']],
#});

exit;

sub mytoken
{
	# overide SUPER::token

	my( $token ) = @_;
	print "found token: ", join( ', ', @{$token} ), "\n";
	
}

sub mytext
{
	# overide SUPER::ether

	my( $text ) = @_;
	print "found text: '$text'\n";
}

