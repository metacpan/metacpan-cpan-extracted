#!/usr/bin/perl

my $assign = (@ARGV and $ARGV[0] eq '--assign');

use warnings;
use strict;

use Ruby;

use Ruby  -eval => <<'EOT';

def ruby_f()
	nil
end

class MyObject
	def ruby_m()
		nil
	end
end


EOT

use Benchmark qw(timethese cmpthese);

sub perl_f{
	undef
}

our $po = bless{};

our $ro = MyObject->new;

our $n = 1000;

my %funcall_void = (
	plf_void => q{ for(1 .. $n){ perl_f() } },
	plm_void => q{ for(1 .. $n){ $po->perl_f() } },

	rbf_void => q{ for(1 .. $n){ ruby_f() } },
	rbm_void => q{ for(1 .. $n){ $ro->ruby_m() } },
);

my %funcall_with_asgn = (
	plf_asgn => q{ for(1 .. $n){ my($v)= perl_f() } },
	plm_asgn => q{ for(1 .. $n){ my($v)= $po->perl_f() } },

	rbf_asgn => q{ for(1 .. $n){ my($v) = ruby_f() } },
	rbm_asgn => q{ for(1 .. $n){ my($v) = $ro->ruby_m() } },
);

print "In Perl:\n";
cmpthese timethese -1 => $assign ? \%funcall_with_asgn : \%funcall_void;


rb_eval(<<'.', __PACKAGE__);

require 'benchmark';

n = self['$n'].to_i * 100;

puts "In Ruby:";
puts "Benchmark: timing #{n} iterations.";

Benchmark.bm{ |x|
	puts "plf_call"
	x.report{ n.times{ perl_f(); } }

	puts "plf_call (prepared)"
	plf = Perl["&perl_f"];
	x.report{ n.times{ plf.call(); } }

	puts "rbf_call"
	x.report{ n.times{ ruby_f(); } }
}
.

