use strict;
use Puppet::Tidy;
use Test::More tests=>3;

my (@output, $source);
my @should_be_output = << 'EOF';
  import conf/*
EOF

###
# One leading hard tab.
###
$source = << 'EOF';
	import conf/*
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "hard tabs");

###
# Some trailing whitespace/tabs
###
$source = << 'EOF';
  import conf/* 	
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Trailing whitespace");

###
# Mixing tabs and regular spaces in front of a line
###
SKIP: {
skip "Arbitrary number of leading spaces not supported yet.", 1;
$source = << 'EOF';
     	  	import conf/* 
EOF

Puppet::Tidy::puppettidy(source => $source, destination => \@output);
is_deeply(@output, @should_be_output, "Mixed leading tab and space");
}
