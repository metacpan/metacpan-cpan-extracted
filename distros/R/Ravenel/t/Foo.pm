package Foo;

use strict;
use Ravenel::Block;
use Data::Dumper;

sub test {
	my $class                    = shift if ( $_[0] eq 'Foo' );
	my Ravenel::Block $block_obj = shift;
	my $block = $block_obj->get_block();

	#print "test block: " . length($block) . "\n";
	#print "||$block||\n";
	#print "--------\n";
	my $res = uc($block) x 3; 

	return $res;
}

sub comment {
	my $class                    = shift if ( $_[0] eq 'Foo' );
	my Ravenel::Block $block_obj = shift;
	my $block = $block_obj->get_block();

	#print "comm block: " . length($block) . "\n";
	#print "||$block||\n";
	#print "--------\n";
	return "<!--$block-->";
}

sub boo {
	my $class                    = shift if ( $_[0] eq 'Foo' );
	my Ravenel::Block $block_obj = shift;
	
	return '';
}

1;
