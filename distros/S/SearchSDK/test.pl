# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use AltaVista::SearchSDK qw(avs_open AVS_OK avs_querymode 
			    avs_getindexmode avs_errmsg
			    avs_buildmode avs_startdoc
			    avs_setdocdate avs_addword
			    avs_setdocdata avs_enddoc
			    avs_makestable avs_compact
			    avs_create_options
			    avs_search
			    avs_getsearchterms
			    avs_getsearchresults
			    avs_search_getdatalen
			    avs_search_getdocid
			    avs_search_getdata
			    avs_search_getdate
			    avs_search_getrelevance
			    avs_search_close
			    avs_search_genrank
			    avs_close
			    avs_version);
$loaded = 1;
$test = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$dir = `pwd`;
chop $dir;
mkdir("$dir/testfiles", 0770) unless (-f "$dir/testfiles");
$status = avs_open("$dir/testfiles", "rw", $av_idx);
if ($status eq AVS_OK) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
}

$status = avs_querymode($av_idx);
if ($status eq AVS_OK) {
    if (avs_getindexmode($av_idx) eq 0) {
	print "ok 3\n";
    } else {
	print "not ok 3\n";
    }
} else {
    $err = avs_errmsg($status);
    print "not ok 3 ($err)\n";
}
$status = avs_buildmode($av_idx);
if ($status eq AVS_OK) {
    if (avs_getindexmode($av_idx) eq 1) {
	print "ok 4\n";
    } else {
	print "not ok 4\n";
    }
} else {
    $err = avs_errmsg($status);
    print "not ok 4 ($err)\n";
}

$status = avs_startdoc($av_idx, "Test File", 0, $startloc);

if ($status eq AVS_OK) {
    print "ok 5\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 5\n";
}

$status = avs_setdocdate($av_idx, "1998", "05", "06");
if ($status eq AVS_OK) {
    print "ok 6\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 6\n";
}
$status = avs_addword($av_idx, "These are some test words", 
		      $startloc, $numwords);

if ($status eq AVS_OK) {
    if ($numwords eq 5) {
	print "ok 7\n";
    } else {
	print "not ok 7\n";
    }
} else {
    $err = avs_errmsg($status);
    print "not ok 6\n";
}

$str = "This is a test document";
$status = avs_setdocdata($av_idx, $str, length($str));

$status = avs_enddoc($av_idx);

if ($status eq AVS_OK) {
    print "ok 8\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 8\n";
}

$status = avs_makestable($av_idx);
$status = avs_compact($av_idx, $done);
while ($done) {
    $status = avs_compact($av_idx, $done);
}
if ($status eq AVS_OK) {
    print "ok 9\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 9\n";
}

if ($status eq AVS_OK) {
    print "ok 9\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 9\n";
}

$options = avs_create_options(100, 100, 1);

$status = avs_search($av_idx, "test words", "", $options, $found, $returned, $termcount, $search);

if ($status eq AVS_OK) {
    print "ok 10\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 10\n";
}

$c = 0;
$hits = 0;
$status = 0;
while ($c < $termcount) {
    $status = avs_getsearchterms($search, $c, $term, $hits);
    if ($status eq AVS_OK) {
	print "ok 11\n";
    } else {
	$err = avs_errmsg($status);
	print "not ok 11 ($err)\n";
    }
    $c++;
}

$c = 0;

$status = avs_getsearchresults($search, 0);
if ($status eq AVS_OK) {
    print "ok 12\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 12 ($err)\n";
}

$len = avs_search_getdatalen($search);
if ($len eq 23) {
    print "ok 13\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 13 ($err)\n";
}

$docid = avs_search_getdocid($search);

$msg = avs_search_getdata($search);
if ($msg eq "This is a test document") {
    print "ok 14\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 14 ($err)\n";
}

avs_search_getdate($search, $year, $month, $day);
if ($status eq AVS_OK) {
    print "ok 15\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 15 ($err)\n";
}

$rel = avs_search_getrelevance($search);
if ($rel eq "1.000000") {
    print "ok 16\n";
} else {
    print "not ok 16\n";
}

$status = avs_search_close($search);

if ($status eq AVS_OK) {
    print "ok 17\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 17\n";
}

$status = avs_search_genrank($av_idx, "test words", "#date", 0, $options, "", $found, $returned, $search);

if ($status eq AVS_OK) {
    print "ok 18\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 18\n";
}

$status = avs_close($av_idx);
if ($status eq AVS_OK) {
    print "ok 19\n";
} else {
    $err = avs_errmsg($status);
    print "not ok 19\n";
}

@version = avs_version();
$i = 0;
while ($version[0][$i]) {
    print $version[0][$i] ."\n";
    $i++;
}
