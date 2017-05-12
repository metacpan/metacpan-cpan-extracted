use strict;
use warnings;

use File::Spec;
use Test::More;
use Fcntl ();

select STDERR;
$|=1;
select STDOUT;

$ENV{PATH} = '/usr/bin:/bin' if ${^TAINT};

# tests don't work in parallel
flock DATA, Fcntl::LOCK_EX();

sub is_windows { $^O =~ /MSWin32/i }

sub sftp_server {
    my ($sscmd, @ssh, $ssname);

    $sscmd = $ENV{NET_SFTP_FOREIGN_TESTING_SFTP_SERVER_PATH};
    return $sscmd if defined $sscmd;

    if(is_windows) {
	$ssname = 'sftp-server.exe';
	my $pf;
	eval {
	    require Win32;
	    $pf = Win32::GetFolderPath(Win32::CSIDL_PROGRAM_FILES());
	};
	$pf = "C:/Program Files/" unless defined $pf;

	@ssh = ("$pf/openssh/bin/ssh.exe",
		"$pf/openssh/usr/bin/ssh.exe",
		"$pf/bin/ssh.exe",
		"$pf/usr/bin/ssh.exe");
    }
    else {
	$ssname = 'sftp-server';
	@ssh = qw( /usr/bin/ssh
		   /usr/local/bin/ssh
		   /usr/local/openssh/bin/ssh
		   /opt/openssh/bin/ssh
                   /opt/ssh/bin/ssh );
    }

    if (eval {require File::Which; 1}) {
	unshift @ssh, File::Which::where('ssh');
    }
    elsif ($^O !~ /MSWin32/i) {
	chomp(my $ssh = `which ssh`);
	unshift @ssh, $ssh if (!$? and $ssh);
    }

 SEARCH: for (@ssh) {
	my ($vol, $dir) = File::Spec->splitpath($_);

	my $up = File::Spec->rel2abs(File::Spec->catpath($vol, $dir, File::Spec->updir));

	for ( File::Spec->catfile($vol, $dir, $ssname),
	      File::Spec->catfile($up, 'lib', $ssname),
              File::Spec->catfile($up, 'lib64', $ssname),
	      File::Spec->catfile($up, 'libexec', $ssname),
	      File::Spec->catfile($up, 'sbin', $ssname),
	      File::Spec->catfile($up, 'lib', 'openssh', $ssname),
              File::Spec->catfile($up, 'lib64', 'openssh', $ssname),
              File::Spec->catfile($up, 'lib', 'misc', $ssname),
              File::Spec->catfile($up, 'lib64', 'misc', $ssname),
	      File::Spec->catfile($up, 'usr', 'lib', $ssname),
              File::Spec->catfile($up, 'usr', 'lib64', $ssname),
	      File::Spec->catfile($up, 'usr', 'libexec', $ssname),
	      File::Spec->catfile($up, 'usr', 'sbin', $ssname) ) {

	    if (-x $_) {
		$sscmd = $_;
		last SEARCH;
	    }
	}
    }

    return $sscmd;
}

sub filediff {
    my ($a, $b) = @_;
    open my $fa, "<", $a or do {
        diag "unable to open file $a";
        return;
    };
    open my $fb, "<", $b or do {
        diag "unable to open file $b";
        return;
    };

    binmode $fa;
    binmode $fb;

    while (1) {
	my $la = read($fa, my $da, 2048);
	my $lb = read($fb, my $db, 2048);
	return 1 unless (defined $la and defined $lb);
	return 1 if $la != $lb;
	return 0 if $la == 0;
	return 1 if $la ne $lb;
    }
}

sub mktestfile {
    my ($fn, $count, $data) = @_;

    open DL, '>', $fn
	or die "unable to create test data file $fn";

    print DL $data for (1..$count);
    close DL;
}

sub new_args {
    my $host = $ENV{NET_SFTP_FOREIGN_TESTING_HOST}; # = 'localhost';
    my $backend = $ENV{NET_SFTP_FOREIGN_TESTING_BACKEND};
    my @diag;

    my @args = (timeout => 20);
    if (defined $backend) {
        push @args, backend => $backend;
        push @diag, "using $backend backend";
    }
    if (defined $host) {
        push @diag, "connecting to host $host";
        push @args, host => $host;
    }
    else {
        my $ss_cmd = sftp_server;
        defined $ss_cmd or plan skip_all => 'sftp-server not found';
        push @diag, "sftp-server found at $ss_cmd";

        if ($ENV{NET_SFTP_FOREIGN_TESTING_WITH_WINE}) {
            push @diag, "running it with wine!";
            $ss_cmd = [wine => $ss_cmd];
        }

        push @args, open2_cmd => $ss_cmd;
    }
    diag join(", ", @diag) if @diag;
    @args;
}

sub dump_error {
    my $sftp = shift;
    if (my $error = $sftp->error) {
        my $status = $sftp->status || 0;
        diag sprintf("SFTP error: %s [%d], status: %s [%d]",
                     $error, $error, $status, $status);
    }
}

1;

__DATA__
