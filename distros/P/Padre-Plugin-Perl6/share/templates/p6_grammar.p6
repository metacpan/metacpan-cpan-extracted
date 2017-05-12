use v6;

=begin Pod
	An example of a Perl 6 grammar for 
	a Properties string can have key1=value1;key2=value2;...
=end Pod
grammar Properties {
	rule key { 
		(\w+)
	}
	rule value { 
		(\w+)
	}
	rule entry {
		<key> '=' <value> (';')?
	}
}

my $text = "foo=bar;me=self;";
if $text ~~ /^<Properties::entry>+$/ {
	"Matched".say;
} else {
	"Not Matched".say;
}