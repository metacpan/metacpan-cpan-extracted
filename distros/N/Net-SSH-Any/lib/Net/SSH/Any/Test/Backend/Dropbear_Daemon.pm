package Net::SSH::Any::Test::Backend::Dropbear_Daemon;

use strict;
use warnings;

use Net::SSH::Any;
use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR);

use parent 'Net::SSH::Any::Test::Backend::_Daemon';

sub _validate_backend_opts {
    my $tssh = shift;

    $tssh->SUPER::_validate_backend_opts or return;

    # dropbear and dbclient are resolved here so that they can be used
    # as friends by any other commands
    my $opts = $tssh->{current_opts};
    $tssh->_be_find_cmd('dropbear') // return;
    $tssh->_be_find_cmd('dropbearconvert') // return;
    $tssh->_be_find_cmd('dropbearkey') // return;

    1;
}

my $key_type = 'rsa';

sub _extract_publickey_from_log {
    my ($tssh, $log, $pubkey_path) = @_;
    if (open my($in), '<', $log) {
        local $_;
        while (<$in>) {
            if (/^ssh-$key_type\s+/) {
                if (open my($out), '>', $pubkey_path) {
                    print $out $_;
                    close $out and return 1;
                }
                last;
            }
        }
    }
    $tssh->_set_error(SSHA_BACKEND_ERROR, "unable to extract publickey from dropbearkey log");
    return;
}

sub _create_key {
    my ($tssh, $path) = @_;
    -f "$path.dbk" and -f "$path.pub" and return 1;
    my $tmppath = join('.', $path, $$, int(rand(9999999)));
    my $log_fn = $tssh->_log_fn('dropbearkey');
    if ($tssh->_run_cmd({stdout_file => $log_fn}, 'dropbearkey', -t => $key_type, -s => 1024, -f => "$tmppath.dbk") and
        $tssh->_run_cmd({}, 'dropbearconvert', 'dropbear', 'openssh', "$tmppath.dbk", $tmppath) and
        $tssh->_extract_publickey_from_log($log_fn, "$tmppath.pub")) {
        unlink $path;
        unlink "$path.pub";
        unlink "$path.dbk";
        chmod 0644, "$tmppath.pub";
        if (rename $tmppath, $path and
            rename "$tmppath.pub", "$path.pub" and
            rename "$tmppath.dbk", "$path.dbk") {
            $tssh->_log("key generated $path");
            return 1;
        }
    }
    $tssh->_or_set_error(SSHA_BACKEND_ERROR, "key generation failed");
    return;
}

sub _be_find_cmd {
    my $tssh = shift;
    my $find_opts = (ref($_[0]) ? shift : {});
    my ($name, $friend, $app, $default) = @_;
    my $opts = $tssh->{current_opts};
    $tssh->SUPER::_be_find_cmd($find_opts,
                               $name,
                               $friend // $opts->{local_dropbear_cmd},
                               $app    // { POSIX => 'Dropbear', MSWin => 'Cygwin' },
                               $default);
}

sub _start_and_check {
    my $tssh = shift;

    $tssh->_create_all_keys or return;

    my $opts = $tssh->{current_opts};
    $tssh->{daemon_proc} = $tssh->_run_cmd({async => 1},
                                           'dropbear', '-E', '-s',
                                           -r => "$opts->{host_key_path}.dbk",
                                           -U => "$opts->{user_key_path}.pub",
                                           -p => "localhost:$opts->{port}",
                                           -P => $tssh->_backend_wfile('dropbear.pid'));

    $tssh->_check_daemon_and_set_uri and return 1;
    $tssh->_stop;
    ()
}

sub _daemon_name { 'dropbear' }

1;
