
# Useful routines used by the test scripts

package ModTest;

use strict;
use Socket;
use Cwd;

my $version	= `httpd -v` =~ /Apache.2/ ? 2 : 1;
my $srvroot	= "/tmp/mod_persistentperl${version}_test";
my $srvport	= 8528 + $version;
my $tcp_proto	= getprotobyname('tcp');
my $lo_addr	= inet_aton('localhost');

sub mod_dir {
    &Cwd::cwd;
}

sub docroot {
    &mod_dir . '/t/docroot';
}

sub get_httpd_pid {
    my $pid = `cat $srvroot/httpd.pid 2>/dev/null`;
    chop $pid;
    return ($pid && kill(0, $pid)) ? $pid : 0;
}

sub write_conf { my $extracfg = shift; 
    my($mod_dir, $docroot, $grp) = (&mod_dir, &docroot, $));
    $grp =~ s/\s.*//;
    my $module = $ENV{PERPERL_MODULE}
	|| ($version == 1
	    ? "$mod_dir/mod_persistentperl.so" : "$mod_dir/.libs/mod_persistentperl.so");
    my $backend = $ENV{PERPERL_BACKENDPROG}
	|| "$mod_dir/../perperl_backend/perperl_backend";

    foreach my $f ($module, $backend) {
	die "Cannot locate ${f}: $!\n" unless -f $f;
    }

    # Can't run apache as user 0 (root)
    my $user = $> ? "#$>" : 'nobody';

    my $cfg = "
	ServerRoot		$srvroot
	User			$user
	Group			#$grp
	ServerName		localhost
	DocumentRoot		$docroot
	ErrorLog		error_log
	PidFile			httpd.pid
	LockFile		lock_file
	Options			+ExecCGI
	LoadModule		persistentperl_module $module
	PersistentBackendProg	$backend
	<Directory $docroot/perperl>  
	DefaultType		 persistentperl-script
	</Directory>		 
	<IfModule mod_mime.c>
	TypesConfig /dev/null
	</IfModule>
    ";
    if ($version > 1) {
	$cfg .= "
	Listen			$srvport
	";
    } else {
	$cfg .= "
	Port			$srvport
	AddModule		mod_persistentperl.c
	AccessConfig		/dev/null
	ResourceConfig		/dev/null
	ScoreBoardFile		/dev/null
	";
    }
    $cfg .= $extracfg if (defined($extracfg));
    $cfg =~ s/\n\s+/\n/g;

    mkdir($srvroot, 0777);
    open(F, ">$srvroot/httpd.conf") || die;
    print F $cfg;
    close(F);
}

sub find_httpd {
    my $x = `apxs -q SBINDIR` . '/httpd';
    return -x $x ? $x : 'httpd';
}

sub abort_test {
    $| = 1;
    print "1..0 # Skipped: can't start httpd in this configuration\n";
    exit;
};

sub start_httpd {
    &write_conf(@_);
    my $pid = &get_httpd_pid;
    if ($pid && kill(0, $pid)) {
	kill(9, $pid);
	sleep 1;
    }
    my $x = $|; $| = 1; print ""; $| = $x; # Avoid double-flush on stdout.
    if (fork == 0) {
	close(STDOUT);
	close(STDERR);
	if (fork == 0) {
	    open(STDOUT, ">>$srvroot/httpd.stdout");
	    open(STDERR, ">&STDOUT");
	    $| = 1;
	    print 'Startup ', scalar localtime, "\n";
	    my $httpd = &find_httpd;
	    eval {exec(split(/ /, "$httpd -X -d $srvroot -f httpd.conf"))};
	    print STDERR "cannot exec httpd: $!\n";
	    die;
	}
	exit 0;
    }
    wait;
    for (my $tries = 4; $tries; --$tries) {
	my $test = html_get('/htmltest');
	# print STDERR "debug=$test\n";
	return if $test =~ /html test/i;
	sleep(1);
    }
    &abort_test;
}

sub http_get { my $relurl = shift;
    my $paddr = sockaddr_in($srvport, $lo_addr);
    socket(SOCK, PF_INET, SOCK_STREAM, $tcp_proto);
    return '' unless connect(SOCK, $paddr);
    my $oldfh = select SOCK;
    $| = 1;
    print "GET $relurl HTTP/1.0\n\n";
    select $oldfh;
    my @ret;
    eval {
	local $SIG{ALRM} = sub {die "alarm clock"};
	alarm 2;
	@ret = <SOCK>;
	alarm 0;
    };
    close(SOCK);
    return wantarray ? @ret : join('', @ret);
}

sub html_get { 
    my @lines = &http_get(@_);
    if (@lines) {
	while ($lines[0] =~ /\S/) { shift @lines }
	shift @lines;
	return wantarray ? @lines : join('', @lines);
    }
    return '';
}

sub touchem { my $scripts = shift;
    my $docroot = &docroot;
    foreach my $scr (@{$scripts || []}) {
	$scr = "$docroot/$scr";
	die "$scr: $!\n" unless -f $scr;
	utime time, time, $scr;
    }
}

sub set_alarm { my $secs = shift;
    $SIG{ALRM} = sub { print "not ok\n"; exit };
    alarm($secs);
}

sub test_init { my($timeout, $scripts, $extracfg) = @_;
    &set_alarm($timeout);
    &touchem($scripts);
    &start_httpd($extracfg);
}

END {
    my $pid = &get_httpd_pid;
    kill(9, $pid) if ($pid);
}

1;
