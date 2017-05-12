#!/usr/bin/perl

my @tests;

BEGIN {
	@tests = ( 1, 2, '2a', 3..6, '6a', 7, '7a', 8..26 );
}

use strict;
use FindBin;
use Data::Dumper;
use Test::More tests => ( scalar(@tests) * 2 );

my %output;

$output{'1'} = "
Dear dextius,

We have received your request for a quote for ipad, and have calculated that it can be delivered to you by 3 April, 2010 at a cost of approximately 699.99.

Thank you for your interest,

Acme Integrated foocorp

";

$output{'2'} = "
	Hello

	Hello

	Hello


";

$output{'2a'} = "<!--
	Hello
-->

";

$output{'3'} = "ABCDEFG\n";

$output{'4'} = "\n\t<html>
		<div>\"Hello\"|bar|</div>
	</html>\n";

$output{'5'} = "<!--3. Hello, Goodbye-->\n";

$output{'6'} = "
	<html>
		
			<DIV>\"HELLO\" BAR </DIV>
		
			<DIV>\"HELLO\" BAR </DIV>
		
			<DIV>\"HELLO\" BAR </DIV>
		
	</html>
";

$output{'6a'} = "
	<html>
		
			<DIV>\"HELLO\" 
				
					JAR COW BAR COW
				
					ZAR ZAZ ZOO ZAZ
				 
			</DIV>
		
			<DIV>\"HELLO\" 
				
					JAR COW BAR COW
				
					ZAR ZAZ ZOO ZAZ
				 
			</DIV>
		
			<DIV>\"HELLO\" 
				
					JAR COW BAR COW
				
					ZAR ZAZ ZOO ZAZ
				 
			</DIV>
		
	</html>
	
";

$output{'7'} = "
<html>

<!--
<DIV>\"HELLO\" BAR </DIV>
-->

<!--
<DIV>\"HELLO\" BAR </DIV>
-->

<!--
<DIV>\"HELLO\" BAR </DIV>
-->

</html>
";

$output{'7a'} = "<html><!--<DIV>\"HELLO\"</DIV>--><!--<DIV>\"HELLO\"</DIV>--><!--<DIV>\"HELLO\"</DIV>--></html>\n";

$output{'8'} = "
        <!-- GARGH
                BOO  BLAH
                        MooooMooooMoooo
                 BOO
                ABCDEFG
        -->
	
";

$output{'9'} = "
        BLAH 288 BLAH |
                <!-- GARGH
                        BOO  BLAH
                                MooooMooooMoooo
                         BOO
                        ABCDEFG
                -->
        | BLAH
	
";

$output{'10'} = "
	BOO 
        	BLAH 87 BLAH |
			<!--
				
>p/<gfedcba>p<	


			-->
        	| BLAH
	 BOO
	
";

$output{'11'} = "
	BOO 
        	BLAH 81 BLAH |
			<br/> Beeper!
			<!--
				<div> Herro </div>
			-->
        	| BLAH
	 BOO
	
";

$output{'12'} = "
	
		1
        	
			2
			
				3
			
				3
			
				3
			
        	
			2
			
				3
			
				3
			
				3
			
        	
	
	
";

$output{'13'} = "
	4
        	 3 
			2
			2
			 
		 3 
			2
			2
			 
		 3 
			2
			2
			 
		
	4
        	 3 
			2
			2
			 
		 3 
			2
			2
			 
		 3 
			2
			2
			 
		
	4
        	 3 
			2
			2
			 
		 3 
			2
			2
			 
		 3 
			2
			2
			 
		
	4
        	 3 
			2
			2
			 
		 3 
			2
			2
			 
		 3 
			2
			2
			 
		
	
	
";

$output{'14'} = "
	
		4
		4
		4
		4
		
	
	
";

$output{'15'} = "
BLAH 12 BLAH |
	1. Hello
	| BLAH
";

$output{'15a'} = "
			BLAH 18 BLAH |
				1. Hello
				| BLAH
";

$output{'16'} = "
		m0t0r0la
		n1xus on1
	
";

$output{'17'} = qr/^Before \d+, \w+ \w+\s+\d+ \d{2}:\d{2}:\d{2} \d{4} After\n$/;

$output{'18'} = qr/^Before \d+, \w+ \w+\s+\d+ \d{2}:\d{2}:\d{2} \d{4} After\n$/;

$output{'19'} = "
<html>
	
		<p>12345 abcdef {c} 12345</p>
	
		<p>23456 bcdefg {c} 23456</p>
	
		<p>34567 cdefgh {c} 34567</p>
	
</html>
	
";

$output{'20'} = qr/^\s*(THIS SHOULD BE UPPER CASE!|!esac reppu eb dluohs siht)\s*$/s;

$output{'21'} = qr#(<tr><td>dextius</td><td>SrA</td><td>12345</td></tr>|<tr><td>No Rows returned</td></tr>)#;

$output{'22'} = "
<html>
	
		<p>12345 abcdef moo 12345</p>
		
		<p>blaaah</p>
		
	
</html>
";

$output{'23'} = "
<html>
	
		<p>12345 abcdef {c} 12345</p>
	
		<p>23456 bcdefg {c} 23456</p>
	
		<p>34567 cdefgh {c} 34567</p>
	
</html>
";

$output{'24'} = "
	<html>
		<div>oomBAR</div>
		<div>tsetWOAHoomBAR</div>
	</html>
";

$output{'25'} = qr/^\s*(<p>It's your lucky day! blue 25 blue<\/p>|<p>Default content blue 25<\/p>)\s*$/s;

$output{'26'} = "
<html>
	
		<p>12345 abcdef moo 12345</p>
		
		<p>blaaah</p>
		<p>1 2 3 4 5</p>
		
		
			<p>x</p>
			<p>67 89</p>
		
	
</html>
";

foreach my $t ( @tests ) {
	foreach my $v ( 'static', 'dynamic' ) {
		my $res = `$FindBin::Bin/test${t}_$v`;
		if ( ref($output{$t}) ) {
			if ( $res =~ $output{$t} ) {
				ok(1, "$t, $v");
			} else {
				print "|" . $res . "|\n";
				ok(0, "$t, $v");
			}
		} else {
			if ( $output{$t} eq $res ) {
				ok(1, "$t, $v");
			} else {
				print "|" . $res . "|\n";
				ok(0, "$t, $v");
			}
		}
	}
}

