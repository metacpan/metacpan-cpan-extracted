#!perl -w
use Ruby::Run;

Perl.eval("use Encode");

require 'nkf'
require "benchmark";

class ::String

	@@Encode = Perl.Package("Encode");

	def from_to(from, to)
		pstr = Perl.String(self);

		@@Encode.from_to(pstr, from, to);

		pstr;
	end

end

str = "PerlのEncode.pmを使って文字コードを変換します。"

puts(str);
puts("Encode.pm: " + str.from_to("Shift_JIS", "ISO-2022-JP"));
puts("NKF.rb:    " + NKF.nkf("-Sj", str));

from = Perl.String("Shift_JIS");
to   = Perl.String("ISO-2022-JP");

Benchmark.bm { |x|
	GC.start;
	puts "Encode::from_to";
	x.report{ 10000.times { str.from_to(from, to)  } }

	GC.start;
	puts "NKF.nkf";
	x.report{ 10000.times { NKF.nkf("-Sj", str) } }
}
