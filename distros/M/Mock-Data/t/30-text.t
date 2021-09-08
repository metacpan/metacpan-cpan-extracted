#! /usr/bin/env perl
use Test2::V0;
use Mock::Data;
use Mock::Data::Plugin::Text;

=head1 DESCRIPTION

This unit test checks the output of the Text plugin

=cut

subtest word => sub {
	my $mock= Mock::Data->new(['Text']);
	like( $mock->word, qr/^\w+$/, 'one word' );
	like( $mock->word(20), qr/^\w{20}$/, '20 char word' );
	like( $mock->word([40,46]), qr/^\w{40,46}$/, '40-46 char word' );
};

subtest words => sub {
	my $mock= Mock::Data->new(['Text']);
	like( $mock->words(50), qr/^[\w ]{50}/, '50 chars of words' );
	like( $mock->words([30,50]), qr/^[\w ]{30,50}/, '30-50 chars of words' );
	like( $mock->words({ count => 5 }), qr/^(\w+ ){4}\w+$/, '5 words' );
};

subtest lorem_ipsum => sub {
	my $mock= Mock::Data->new(['Text']);
	ok( length($mock->lorem_ipsum(50)) <= 50, 'length limit' );
};

done_testing;
