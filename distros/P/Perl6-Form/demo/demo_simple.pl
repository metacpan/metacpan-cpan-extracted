use Perl6::Form;

$w = "1.2\n1.3\n1.4\nfoo\n1.9999999\n9999.999\n9999.9999";
$x = "the    firstest    field    is    here and         there";
$y = "     the second field is here";
@z = qw(heyah hey heyah hey heyah hey);

print form {out=>\*STDERR, single=>"=", ws=>qr/[^\S\n]+/,
	  # layout=>'across'
	 },
      "= hi [{:[[[[:}] there [{:>>}] you {:III:}{]][[} -> {]]].[[}",
      'demo',
			 $x,              {bfill=>'*  '}, 
							  $y,        {bfill=>'+'},
										 $x,    \@z,       {rfill=>0}, $w;

print "\n\n", substr($y, pos$y), "\n";
