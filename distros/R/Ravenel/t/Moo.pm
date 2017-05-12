package Moo;

use strict;
use Data::Dumper;
use Ravenel::Block;

sub cow {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	#print "cow\n";

	my $out = $block x 3;
}
sub laa {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	#print "laa\n";

	return "ABCDEFG";
}
sub boo {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	#print "boo\n";

	return "BOO $block BOO";
}
sub foo {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	#print "foo\n";

	my $res = "<!--$block-->";
	#print "INSIDE FOO!\n";
	#print $res . "\n";

	return $res;
}
sub blah {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();
	
	my $res = "BLAH " . length($block) . " BLAH |" . $block . "| BLAH";
	
	return $res;
}

sub waa {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	my $res = reverse($block);
	return $res;
}

sub ret {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();
	
	return $block x int($block);
}

sub make_ret {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();

	$block =~ s/\{func\}/Moo:ret/g;
	return $block;
}

sub test_format {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;

	my $str = {
		'a' => time(),
		'b' => '' . localtime(),
	};

	return $block_obj->format($str);
}

sub arg_test {
        my $class                    = shift if ( $_[0] eq __PACKAGE__ );
        my Ravenel::Block $block_obj = shift;
	my $block                    = $block_obj->get_block();
	my $arg                      = $block_obj->get_arguments();

	my $outbound;
	foreach my $a ( keys(%{$arg}) ) {
		$outbound .= reverse($a) . uc($arg->{$a});
	}

	$arg->{'test'} = 'woah'; # XXX Side effect?
	return $outbound;
}

1;
