# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use constant THIS_CLASS => 'Proc::Daemontools';
use Test::More;

$have_svscan = 0;

if ($ps = find_svscan()) {
    plan tests => 3;
} else {
    plan tests => 1;
}


use_ok(THIS_CLASS);

$SVC = "/usr/local/bin/svc";

if ( $ps ) {
    $SKIP_REASON = "WARNING: the svc file cannot be found on its default location " .
	  "\'$SVC\'. Skipping the remaining tests.";
    SKIP: {
	skip ($SKIP_REASON, 2) if (! -e $SVC);
	$SERVICE_DIR = (split(/\s{1,}/, $ps))[1];
	eval {
	    if (-e $SERVICE_DIR) { 
		$svc = new Proc::Daemontools (SERVICE_DIR => $SERVICE_DIR);
	    } else {
		$svc = new Proc::Daemontools;
	    }
	};
	if ($@) {
	    print "ERROR: the following error ocurred when trying to create a ",
		  THIS_CLASS, " object:\n", $@;
	}
	ok( defined $svc,		'a new ' . THIS_CLASS . " object was created" );
	ok( $svc->isa(THIS_CLASS),	"testing it´s classname" );
    }
}

sub find_svscan() { # returns: string
    # Searching for the svscan process
    $ps = `ps -C ssvscan -o args= 2>&1`;
    if ( $? == 0 ) {
	return $ps;
    } else { # ps failed for some reason
	# if we find svscan on this machine, we return the string that 
	# ps should output:
	if (-e "/usr/local/bin/svscan") {
	    return "svscan /service";
	}
	return undef;
    }
}
