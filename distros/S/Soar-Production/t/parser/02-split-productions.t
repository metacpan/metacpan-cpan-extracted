#Test that the parser can separate files into productions
use strict;
use warnings;
use Test::More;
use t::parser::TestSoarProdParser;
plan tests => 5 + 1*blocks;

use Soar::Production::Parser;
use FindBin qw($Bin);

# use vars '@INC';
# print join ',', @INC;

# use File::Find;
# use File::Find::Closures qw(:all);
use File::Spec::Functions(qw(catdir catfile));

my $path = File::Spec->catdir( $Bin,'examples' );

my $fileNumbers = {
	'readme'			=>	0,
	'b'					=>	2,
	'testmulti'			=>	3,
	'generate-facts'	=>	5,
	'big'				=>	822,
};

my $parser = Soar::Production::Parser->new();
foreach my $file (keys %$fileNumbers){
	my $fullPath = File::Spec->catfile($path, $file . '.soar');
	my $productions = $parser->productions(file => $fullPath, parse => 0);
	is(scalar scalar @$productions, $fileNumbers->{$file}, 'number of productions in ' . $file . '.soar');
}

run_is;

__END__
=== normal
--- input split_prods
sp {xyz
	(state <s> ^foo 1)
-->
}

sp {one
	(state <s> ^commented 1)
-->
}

sp {one
	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}
-->
}
--- expected: 3

=== commented
--- input split_prods
#should load fine
sp {xyz
	(state <s> ^foo 1)
-->
}

#this one shouldn't exist
# sp {one
	# (state <s> ^commented 1)
# -->
# }

#this is fine
sp {one
	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}
-->
}
--- expected: 2

=== quote
--- input get_prods=0
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |##}}}}}{{##|)
}
--- expected chomp
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |##}}}}}{{##|)
}

=== comment character in comment with escaping
--- input get_prods=0
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}
--- expected chomp
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|#|)
}

=== quote and escaping
--- input get_prods=0
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|}}}}}\|{{|)
}
--- expected chomp
sp {literals_test
   (state <s> ^superstate nil)
-->
   (<s> ^literal |\|}}}}}\|{{|)
}

=== unfinished
--- input split_prods
#should load fine
sp {xyz
	(state <s> ^foo 1)
-->
}

sp {one
	(state <s> ^commented 1)
-->
}

#unfinished
sp {one
	-{(state <s> ^foo 1)
		(<s> ^nested baz)
	}
-->
--- expected: 2

