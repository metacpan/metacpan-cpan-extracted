#!/usr/bin/perl

use warnings;
use strict;

use Ruby -all;
use Ruby -eval => <<'__RUBY__';

def hello()
	puts "Hello, #{ message() } world!\n\n"; # ok!
end


__RUBY__

sub message{
	'Ruby.pm';
}

hello(); # ok!

my @ary = qw(Perl Ruby);
my $s   = "!rekcaH s% rehtonA tsuJ";

2->times(sub{ 
	my $i = shift;

	puts( $s->reverse % $ary[ $i ] );
});

puts;
puts "Loaded:";
rubyify(\%INC)->each(sub{
	puts "\t$_[0]";
});
