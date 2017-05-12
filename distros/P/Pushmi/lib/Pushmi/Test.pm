package Pushmi::Test;
use strict;
use warnings;
use Pushmi::Config;

use base 'Exporter';
our @EXPORT = qw(get_dav_server run_pushmi is_svn_output start_memcached check_apache);

use FindBin;
BEGIN {
    $ENV{PATH} = "$FindBin::Bin/../bin:".$ENV{PATH};
    $ENV{SVKNOSVNCONFIG} = 1;
    $SIG{INT} = $SIG{TERM} = sub { exit }; # calls END properly
    $ENV{PUSHMI_CONFIG} = "$FindBin::Bin/pushmi.conf";
}

use SVK::Util qw(can_run abs_path);
use IPC::Run3 'run3';
use Test::More;

my $apache_port = 5008;

my $apxs = $ENV{APXS} || can_run('apxs2') || can_run ('apxs');
my @CLEANUP;

sub run_pushmi {
    system($^X, (map { "-I$_" } @INC), 'bin/pushmi', @_);
    die $! if $?;
    return;
}

sub _mk_cmp_closure {
    my ($exp, $err) = @_;
    my $line = 0;
    sub {
	my $output = shift;
	chomp $output;
	++$line;
	unless (@$exp) {
	    push @$err, "$line: got $output";
	    return;
	}
	my $item = shift @$exp;
	push @$err, "$line: got ($output), expect ($item)\n"
	    unless ref($item) ? ($output =~ m/$item/)
                       	      : ($output eq $item);
    }
}

sub is_svn_output {
    my ($arg, $exp_stdout, $exp_stderr) = @_;
    my $stdout_err = [];
    $exp_stderr ||= [];
    my $ret = run3 ['svn', @$arg], undef,
	_mk_cmp_closure($exp_stdout, $stdout_err), # stdout
	_mk_cmp_closure($exp_stderr, $stdout_err); # stderr
    if (@$stdout_err) {
	@_ = (0, join(' ', 'svn', @$arg));
	diag("Different in line: ".join(',', @$stdout_err));
	goto \&ok;
    }
    else {
	@_ = (1, join(' ', 'svn', @$arg));
	goto \&ok;
    }
}

sub check_apache {
    plan (skip_all => "Test does not run under root") if $> == 0;

    my $apxs = $ENV{APXS} || can_run('apxs2') || can_run ('apxs');
    plan skip_all => "Can't find apxs utility. Use APXS env to specify path" unless $apxs;
}

sub get_dav_server {
    require RunApp::Apache;
    my %args        = @_;
    my $apache_root = $args{apache_root};

    mkdir($apache_root);
    mkdir("$apache_root/logs");

    my $apache = RunApp::Apache->new(
        CTL              => 'RunApp::Control::ApacheCtl',
        root             => $args{apache_root},
        port             => ( $apache_port++ ),
        hostname         => 'localhost',
        webmaster        => 'root@localhost',
        mime_file        => '/etc/mime.types',
        documentroot     => '/tmp',
        report           => 1,
        apxs             => $apxs,
        config_block     => ($args{prelude_config} || '').
qq{
KeepAlive On
# [% AP2_VERSION %]
[% IF AP2_VERSION == '2.2' %]
<IfModule mod_perl.c>
PerlLoadModule Apache::AuthenHook
</IfModule>
[% END %]
<Location /svn>
DAV svn
SVNPath $args{repospath}

AuthType Basic
AuthName "Auth Realm"
} . ( $args{svnpasswd} ? "Require valid-user
AuthUserFile $args{svnpasswd}\n" : '' ) .
    ( $args{svnpolicy} ? "AuthzSVNAccessFile $args{svnpolicy} \n " : '' ).
($args{extra_config} || '').
q{</Location>
});
    my $ret = `$apache->{httpd} -V`;
    my ($ap_version) = $ret =~ m{version: Apache/([\d.]+)};

    $args{extra_modules} ||= [];
    if ($ap_version =~ m/^2\.2/) {
	$ap_version = '2.2';
	push @{$args{extra_modules}}, "auth_basic", "authn_file", "authz_user";
    }
    else {
	$ap_version = '2.0';
	push @{$args{extra_modules}}, "auth";
    }

    $apache->build({ AP2_VERSION => $ap_version,
		     required_modules => [ "dav", "dav_svn", "authz_svn", "log_config", @{$args{extra_modules}}]});

    push @CLEANUP, sub { $apache->stop };
    return ($apache, "http://localhost:$apache->{port}/svn");
}

sub start_memcached {
    my $port = Pushmi::Config->config->{authproxy_port};
    my $memcached_pid;
    my $memcached = can_run('memcached')
	or die "Can't find memcached";

    system($memcached, -p => $port, qw(-l 127.0.0.1 -dP), abs_path("t/memcached.pid"));
    die $! if $?;
    sleep 1;
    open my $fh, '<', 't/memcached.pid' or die $!;
    $memcached_pid = <$fh>;
    diag $memcached_pid;
    chomp $memcached_pid;
    my $pid = $$;
    push @CLEANUP, sub { return unless $$ == $pid;
			 diag 'stopping memcached'; kill 'TERM', $memcached_pid if $memcached_pid };
}

END {
    for (@CLEANUP) {
	$_->();
    }
}

1;
