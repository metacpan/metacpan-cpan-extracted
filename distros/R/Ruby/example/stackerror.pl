#!perl

use Ruby -all, -eval => <<'EOR';

def f(x)
	p x
	f(x+1)
end

EOR


f(0);
