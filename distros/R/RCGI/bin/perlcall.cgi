#!/usr/local/bin/perl

# Change Dumpxs to Dump for Irix
# Remove: ->Purity(1)->Indent(0) for WinNT

use lib '.';

use strict;
use CGI;
use SafeCall;
use Data::Dumper;
use Data::Undumper;		# Undumps using the Safe module

my($cgi) = new CGI;

if ($cgi->param('library_path') =~ 'upload:') {
    upload($cgi);
} else {
    perlcall($cgi);
}
exit;

sub authenticate {
    my($user) = shift;
    my($inpwd) = shift;
    my($pwdfile) = '.rcgipwd';
    my($result) = 0;

    if (-e $pwdfile && -r $pwdfile &&
	$user !~ /^\s*$/ && $inpwd !~ /^\s*$/) {
	open(PASSWD,"$pwdfile");
	while(<PASSWD>) {
	    chomp;
	    my($puser,$ppwd) = split(':');
	    if ($puser eq $user) {
		my($salt) = substr($ppwd,0,2);
		my($pwd) = crypt($inpwd,$salt);
		$result = ($pwd eq $ppwd) ? 1 : 0;
	    }
	}
	close(PASSWD);
    }
    return $result;
}

sub upload {
    my($cgi) = shift;
    my($module)       = $cgi->param('module');
    my($arguments)    = $cgi->param('arguments');
    my($contents,$username,$password) = Data::Undumper::Undump($arguments);

    if (defined($cgi->remote_user) ||
	authenticate($username,$password)) {
	$module =~ s/\:\:/\//g;
	# Handle subdirectories that need creating.
	mkdir_p($module);
	if (open(FILE,"> $module.pm")) {
	    print FILE $contents;
	    close(FILE);
	    my($result) = 'OK';
	    print $cgi->header(-type => 'perl/call',
			       -status => '200 OK');
	    print Data::Dumper->new([ \$result ])->Purity(1)->Indent(0)->Dumpxs,
	    "\n";
	} else {
	    print $cgi->header(-type => 'perl/call',
			       -status => "230 Unable to open: $module.pm");
	}
    } else {
	print $cgi->header(-type => 'perl/call',
			   -status => '220 Unauthenticated connection');
    }
}

sub mkdir_p {
    my($filepath) = shift;
    my(@directory) = split('/',$filepath);
    pop(@directory);	# pop off the filename
    my($path) = shift(@directory);
    if (!-e $path) {
	mkdir($path,0770);
    }
    map {
	$path .= '/' . $_;
	if (!-e $path) {
	    mkdir($path,0770);
	}
    } @directory;
    return $path;
}

sub perlcall {
    my($cgi) = shift;
    my($library_path) = $cgi->param('library_path');
    my($module)       = $cgi->param('module');
    my($subroutine)   = $cgi->param('subroutine');
    my($arguments)    = $cgi->param('arguments');
    my($wantarray)    = $cgi->param('wantarray');
    
    my(@result);			# array result
    my($result);			# scalar result
    my($result_ref);		# reference of result
    my($status);			# SafeCall::Execute return status
    my($string);
    
    if (defined($module) && defined($subroutine) && defined($arguments) &&
	defined($wantarray)) {
	if ($wantarray) {
	    @result = SafeCall::Execute($library_path,$module,$subroutine,\$status,
				      Data::Undumper::Undump($arguments));
	    if (!$status) {
		$result_ref = \@result;
	    }
	} else {
	    $result = SafeCall::Execute($library_path,$module,$subroutine,\$status,
				      Data::Undumper::Undump($arguments));
	    if (!$status) {
		$result_ref = \$result;
	    }
	}
	if ($status) {
	    print $cgi->header(-type => 'perl/call',
			       -status => 200 - $status . ' SafeCall Failed');
	} else {
	    print $cgi->header(-type => 'perl/call',
			       -status => '200 OK');
	    print Data::Dumper->new([ $result_ref ])->Purity(1)->Indent(0)->Dumpxs,
	    "\n";
	}
    } else {
	map {
	    if (!defined($cgi->param($_))) {
		$string .= ' '.$_;
	    }
	}
	( 'module', 'subroutine', 'arguments', 'wantarray' );
	
	print $cgi->header(-type => 'perl/call',
			   -status => '210 Missing Arguments:'.$string);
    }
}
