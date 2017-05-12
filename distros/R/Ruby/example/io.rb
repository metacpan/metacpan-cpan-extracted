#!perl -w
use Ruby::Run;

require 'benchmark';

n = 100_000;

openn = 10_000;

Benchmark.bm do |x|
	GC.start();


	open("foo.txt", "w"); # touch&truncate

	puts "PerlIO";

	puts "open:"
	x.report{
		openn.times{ Perl.open("foo.txt"){} }
	}


	puts " write:";
	x.report{
		Perl.open("foo.txt", "w"){ |io|
			n.times{ |i|
				io.print("[", i, "]\n");
			}
		}
	}
	puts " each_line:";
	x.report{
		Perl.open("foo.txt"){ |io|
			io.each_line{ }
		}
	}
	puts " each_byte:";
	x.report{
		Perl.open("foo.txt"){ |io|
			io.each_byte{ }
		}
	}
	
	puts " read slurp:";
	x.report{
		Perl.open("foo.txt"){ |io|
			io.read(); # slurp
			
		}
	}


	open("foo.txt", "w"); # truncate


	puts "RubyIO";

	puts "open:"
	x.report{
		openn.times{ open("foo.txt"){} }
	}


	puts " write:";
	x.report{
		open("foo.txt", "w"){ |io|
			n.times{ |i|
				io.print("[", i, "]\n");
			}
		}
	}

	puts " each_line"
	x.report{
		open("foo.txt"){ |io|
			io.each_line{ }
		}
	}
	puts " each_byte:";
	x.report{
		open("foo.txt"){ |io|
			io.each_byte{ }
		}
	}
	

	puts " read slurp:";
	x.report{
		open("foo.txt"){ |io|
			io.read(); # slurp
		}
	}


	File.unlink("foo.txt");
end
