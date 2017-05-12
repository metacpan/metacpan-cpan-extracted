use Perl6::Form;

for (<DATA>) {
	($title, $page) = split /[\t\n]+/;
	push @contents, $title;
	push @page, $page;
}

print form
	 {page=>{width=>51},hfill=>'=-'},
	 "{||||{*}|||||}\n\n",
	 "[ Table of Contents ]",
	 {hfill=>' .'},
	 "   {[[[[[{*}[[[[[}{]]]}   ",
	     \@contents,    \@page;

__DATA__
Foreword			i
Preface				iii
Glossary			vi
Introduction		1
The Tempest			7
Two Gentlemen of Verona		17
The Merry Wives of Winsor	27
Twelfh Night				39
Measure for Measure			50
Much Ado About Nothing		62
A Midsummer Night's Dream	73
Love's Labour's Lost		82
The Merchant of Venice	    94
As You Like It				105
