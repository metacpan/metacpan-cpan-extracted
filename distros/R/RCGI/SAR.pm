package SAR;

sub system_activity_report {
    my($length) = shift;

    open(SAR,"sar $length |");
    while(<SAR>) {
	if (/%idle/) {
	    last;
	}
    }
    s/\s+/\t/g;
    my($time, @title) = split("\t");

    my($current) = 0;
    my($usr, $sys, $wio, $idle);
    map {
	if (/usr/) {
	    $usr = $current;
	}
	if (/sys/) {
	    $sys = $current;
	}
	if (/wio/) {
	    $wio = $current;
	}
	if (/idle/) {
	    $idle = $current;
	}
	++$current;
    } @title;
    $_ = <SAR>;
    close(SAR);
    s/\s+/\t/g;
    ($time, @value) = split("\t");
    my($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
	localtime(time());
    $mon++;
    $, = "\t";
    @result = ( "$mon/$mday/$year $time",
	       $value[$usr],$value[$sys],$value[$wio],$value[$idle] );
    return @result;
}

1;
