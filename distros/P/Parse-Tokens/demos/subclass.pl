#!/usr/local/bin/perl

package PTSample;

use strict;
use base 'Parse::Tokens';

my $input;
while(<>) { $input .= $_; }

PTSample->new->parse({
	text => $input,
	delimiters => [['<?','?>']],
});

exit;

sub pre_parse
{
	# overide SUPER::pre_parse

	my( $self ) = @_;
	print "getting ready to parse!\n";
	
}

sub token
{
	# overide SUPER::token

	my( $self, $token) = @_;
	print "found token: ", join( ', ', @{$token} ), "\n";
	
}

sub ether
{
	# overide SUPER::ether

	my( $self, $text ) = @_;
	print "found text: '$text'\n";
}

sub post_parse
{
	# overide SUPER::post_parse

	my( $self ) = @_;
	print "all done parsing!\n";
	
}

