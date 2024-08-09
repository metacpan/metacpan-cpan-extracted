package Net::OpenSSH::More;
$Net::OpenSSH::More::VERSION = '1.00';
#ABSTRACT: Net::OpenSSH submodule with many useful features

use strict;
use warnings;

use parent 'Net::OpenSSH';

use Data::UUID        ();
use Expect            ();
use File::HomeDir     ();
use File::Temp        ();
use Fcntl             ();
use IO::Pty           ();
use IO::Socket::INET  ();
use IO::Socket::INET6 ();
use IO::Stty          ();
use List::Util qw{first};
use Net::DNS::Resolver ();
use Net::IP            ();
use Time::HiRes        ();
use Term::ANSIColor    ();


my %defaults = (
    'user'                 => $ENV{'USER'} || getpwuid($>),
    'port'                 => 22,
    'use_persistent_shell' => 0,
    'output_prefix'        => '',
    'home'                 => File::HomeDir->my_home,
    'retry_interval'       => 6,
    'retry_max'            => 10,
);

our %cache;
our $disable_destructor = 0;

###################
# PRIVATE METHODS #
###################

my $die_no_trace = sub {
    my ( $full_msg, $summary ) = @_;
    $summary ||= 'FATAL';
    my $carp = $INC{'Carp/Always.pm'} ? '' : ' - Use Carp::Always for full trace.';
    die "[$summary] ${full_msg}${carp}";
};

my $check_local_perms = sub {
    my ( $path, $expected_mode, $is_dir ) = @_;
    $is_dir //= 0;
    my @stat = stat($path);
    $die_no_trace->(qq{"$path" must be a directory that exists}) unless !$is_dir ^ -d _;
    $die_no_trace->(qq{"$path" must be a file that exists})      unless $is_dir ^ -f _;
    $die_no_trace->(qq{"$path" could not be read})               unless -r _;

    my $actual_mode = $stat[2] & 07777;
    $die_no_trace->( sprintf( qq{Permissions on "$path" are not correct: got=0%o, expected=0%o}, $actual_mode, $expected_mode ) ) unless $expected_mode eq $actual_mode;
    return 1;
};

my $resolve_login_method = sub {
    my ($opts) = @_;

    my $chosen = first { $opts->{$_} } qw{key_path password};
    $chosen //= '';
    undef $chosen          if $chosen eq 'key_path' && !$check_local_perms->( $opts->{'key_path'}, 0600 );
    return $chosen         if $chosen;
    return 'SSH_AUTH_SOCK' if $ENV{'SSH_AUTH_SOCK'};
    my $fallback_path = "$opts->{'home'}/.ssh/id";
    ( $opts->{'key_path'} ) = map { "${fallback_path}_$_" } ( first { -s "${fallback_path}_$_" } qw{dsa rsa ecdsa} );

    $die_no_trace->('No key_path or password specified and no active SSH agent; cannot connect') if !$opts->{'key_path'};
    $check_local_perms->( $opts->{'key_path'}, 0600 )                                            if $opts->{'key_path'};

    return $opts->{'key_path'};
};

my $get_dns_record_from_hostname = sub {
    my ( $hostname, $record_type ) = @_;
    $record_type ||= 'A';

    my $reply = Net::DNS::Resolver->new()->search( $hostname, $record_type );
    return unless $reply;
    return { map { $_->type() => $_->address() } grep { $_->type eq $record_type } ( $reply->answer() ) };
};

# Knock on the server till it responds, or doesn't. Try both ipv4 and ipv6.
my $ping = sub {
    my ($opts) = @_;

    my $timeout = 30;
    my ( $host_info, $ip, $r_type );
    if ( my $ip_obj = Net::IP->new( $opts->{'host'} ) ) {
        $r_type = $ip_obj->ip_is_ipv4 ? 'A' : 'AAAA';
        $ip     = $opts->{'host'};
    }
    else {
        my $host_info = first { $get_dns_record_from_hostname->( $opts->{'host'}, $_ ) } qw{A AAAA};
        ($r_type) = keys(%$host_info);
        if ( !$host_info->{$r_type} ) {
            require Data::Dumper;
            die "Can't determine IP type. " . Data::Dumper::Dumper($host_info);
        }
        $ip = $host_info->{$r_type};
    }
    my %family_map = ( 'A' => 'INET', 'AAAA' => 'INET6' );
    my $start      = time;

    while ( ( time - $start ) <= $timeout ) {
        return 1 if "IO::Socket::$family_map{$r_type}"->new(
            'PeerAddr' => $ip,
            'PeerPort' => $opts->{'port'},
            'Proto'    => 'tcp',
            'Timeout'  => $timeout,
        );
        diag( { '_opts' => $opts }, "[DEBUG] Waiting for response on $ip:$opts->{'port'} ($r_type)..." ) if $opts->{'debug'};
        select undef, undef, undef, 0.5;    # there's no need to try more than 2 times per second
    }
    return 0;
};

my $init_ssh = sub {
    my ( $class, $opts ) = @_;

    # Always clear the cache if possible when we get here.
    if ( $opts->{'_cache_index'} ) {
        local $disable_destructor = 1;
        undef $cache{ $opts->{'_cache_index'} };
    }

    # Try not to have disallowed ENV chars. For now just transliterate . into _
    # XXX TODO This will be bad with some usernames/domains.
    # Maybe need to run host through punycode decoder, etc.?
    if ( !$opts->{'_host_sock_key'} ) {
        $opts->{'_host_sock_key'} = "NET_OPENSSH_MASTER_$opts->{'host'}_$opts->{'user'}";
        $opts->{'_host_sock_key'} =~ tr/./_/;
    }

    # Make temp dir go out of scope with this object for ctl paths, etc.
    # Leave no trace!
    $opts->{'_tmp_obj'} = File::Temp->newdir() if !$opts->{'_tmp_obj'};
    my $tmp_dir = $opts->{'_tmp_obj'}->dirname();
    diag( { '_opts' => $opts }, "Temp dir: $tmp_dir" ) if $opts->{'debug'};
    my $temp_fh;

    # Use an existing connection if possible, otherwise make one
    if ( $ENV{ $opts->{'_host_sock_key'} } && -e $ENV{ $opts->{'_host_sock_key'} } ) {
        $opts->{'external_master'} = 1;
        $opts->{'ctl_path'}        = $ENV{ $opts->{'_host_sock_key'} };
    }
    else {
        if ( !$opts->{'debug'} ) {
            open( $temp_fh, ">", "$tmp_dir/STDERR" ) or $die_no_trace->("Can't open $tmp_dir/STDERR for writing: $!");
            $opts->{'master_stderr_fh'} = $temp_fh;
        }
        $opts->{'ctl_dir'}     = $tmp_dir;
        $opts->{'strict_mode'} = 0;

        $opts->{'master_opts'} = [
            '-o' => 'StrictHostKeyChecking=no',
            '-o' => 'GSSAPIAuthentication=no',
            '-o' => 'UserKnownHostsFile=/dev/null',
            '-o' => 'ConnectTimeout=180',
            '-o' => 'TCPKeepAlive=no',
        ];
        push @{ $opts->{'master_opts'} }, '-v' if $opts->{'debug'};
        if ( $opts->{'key_path'} ) {
            push @{ $opts->{'master_opts'} }, '-o', 'IdentityAgent=none';
        }

        # Attempt to use the SSH agent if possible. This won't hurt if you use -k or -P.
        # Even if your sock doesn't work to get you in, you may want it to do something on the remote host.
        # Of course, you may want to disable this with no_agent if your system is stupidly configured
        # with lockout after 3 tries and you have 4 keys in agent.

        # Anyways, don't just kill the sock for your bash session, restore it in DESTROY
        $opts->{'_restore_auth_sock'} = delete $ENV{SSH_AUTH_SOCK} if $opts->{'no_agent'};
        $opts->{'forward_agent'}      = 1                          if $ENV{'SSH_AUTH_SOCK'};
    }

    my $status = 0;
    my $self;
    foreach my $attempt ( 1 .. $opts->{'retry_max'} ) {

        local $@;
        my $up = $ping->($opts);
        if ( !$up ) {
            $die_no_trace->("$opts->{'host'} is down!") if $opts->{die_on_drop};
            diag( { '_opts' => $opts }, "Waiting for host to bring up sshd, attempt $attempt..." );
            next;
        }

        # Now, per the POD of Net::OpenSSH, new will NEVER DIE, so just trust it.
        my @base_module_opts =
          qw{host user port password passphrase key_path gateway proxy_command batch_mode ctl_dir ctl_path ssh_cmd scp_cmd rsync_cmd remote_shell timeout kill_ssh_on_timeout strict_mode async connect master_opts default_ssh_opts forward_agent forward_X11 default_stdin_fh default_stdout_fh default_stderr_fh default_stdin_file default_stdout_file default_stderr_file master_stdout_fh master_sdterr_fh master_stdout_discard master_stderr_discard expand_vars vars external_master default_encoding default_stream_encoding default_argument_encoding password_prompt login_handler master_setpgrp master_pty_force};
        my $class4super = "Net::OpenSSH::More";

        # Subclassing here is a bit tricky, especially *after* you have gone down more than one layer.
        # Ultimately we only ever want the constructor for Net::OpenSSH, so start there and then
        # Re-bless into subclass if that's relevant.
        $self = $class4super->SUPER::new( map { $_ => $opts->{$_} } grep { $opts->{$_} } @base_module_opts );
        my $error = $self->error;
        next unless ref $self eq 'Net::OpenSSH::More' && !$error;
        bless $self, $class if ref $self ne $class;

        if ( $temp_fh && -s $temp_fh ) {
            seek( $temp_fh, 0, Fcntl::SEEK_SET );
            local $/;
            $error .= " " . readline($temp_fh);
        }

        if ($error) {
            $die_no_trace->("Bad password passed, will not retry SSH connection: $error.") if ( $error =~ m{bad password}                       && $opts->{'password'} );
            $die_no_trace->("Bad key, will not retry SSH connection: $error.")             if ( $error =~ m{master process exited unexpectedly} && $opts->{'key_path'} );
            $die_no_trace->("Bad credentials, will not retry SSH connection: $error.")     if ( $error =~ m{Permission denied} );
        }

        if ( defined $self->error && $self->error ne "0" && $attempt == 1 ) {
            $self->diag( "SSH Connection could not be established to " . $self->{'host'} . " with the error:", $error, 'Will Retry 10 times.' );
        }
        if ( $status = $self->check_master() ) {
            $self->diag( "Successfully established connection to " . $self->{'host'} . " on attempt #$attempt." ) if $attempt gt 1;
            last;
        }

        sleep $opts->{'retry_interval'};
    }
    $die_no_trace->("Failed to establish SSH connection after $opts->{'retry_max'} attempts. Stopping here.") if ( !$status );

    # Setup connection caching if needed
    if ( !$opts->{'no_cache'} && !$opts->{'_host_sock_key'} ) {
        $self->{'master_pid'} = $self->disown_master();
        $ENV{ $opts->{'_host_sock_key'} } = $self->get_ctl_path();
    }

    #Allow the user to unlink the host sock if we need to pop the cache for some reason
    $self->{'host_sock'} = $ENV{ $opts->{'_host_sock_key'} };

    return $self;
};

my $connection_check = sub {
    my ($self) = @_;
    return 1 if $self->check_master;
    local $@;
    local $disable_destructor = 1;
    eval { $self = $init_ssh->( __PACKAGE__, $self->{'_opts'} ) };
    return $@ ? 0 : 1;
};

# Try calling the function.
# If it fails, then call $connection_check to reconnect if needed.
#
# The goal is to avoid calling $connection_check
# unless something goes wrong since it adds about
# 450ms to each ssh command.
#
# If the control socket has gone away, call
# $connection_check ahead of time to reconnect it.
my $call_ssh_reinit_if_check_fails = sub {
    my ( $self, $func, @args ) = @_;

    $connection_check->($self) if !-S $self->{'_ctl_path'};

    local $@;
    my @ret       = eval { $self->$func(@args) };
    my $ssh_error = $@ || $self->error;
    warn "[WARN] $ssh_error" if $ssh_error;
    return @ret              if !$ssh_error;

    $connection_check->($self);
    return ( $self->$func(@args) );
};

my $post_connect = sub {
    my ( $self, $opts ) = @_;

    $self->{'persistent_shell'}->close() if $self->{'persistent_shell'};
    undef $self->{'persistent_shell'};

    return;
};

my $trim = sub {
    my ($string) = @_;
    return '' unless length $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
};

my $send = sub {
    my ( $self, $line_reader, @command ) = @_;

    $self->diag( "[DEBUG][$self->{'_opts'}{'host'}] EXEC " . join( " ", @command ) ) if $self->{'_opts'}{'debug'};

    my ( $pty, $err, $pid ) = $call_ssh_reinit_if_check_fails->( $self, 'open3pty', @command );
    $die_no_trace->("Net::OpenSSH::open3pty failed: $err") if ( !defined $pid || $self->error() );

    $self->{'_out'} = "";
    $line_reader = sub {
        my ( $self, $out, $stash_param ) = @_;
        $out =~ s/[\r\n]{1,2}$//;
        $self->{$stash_param} .= "$out\n";
        return;
      }
      if ref $line_reader ne 'CODE';

    # TODO make this async so you can stream STDERR *in order*
    # with STDOUT as well
    # That said, most only care about error if command fails, so...
    my $out;
    $line_reader->( $self, $out, '_out' ) while $out = $pty->getline;
    $pty->close;

    # only populate error if there's an error #
    $self->{'_err'} = '';
    $line_reader->( $self, $out, '_err' ) while $out = $err->getline;
    $err->close;

    waitpid( $pid, 0 );
    return $? >> 8;
};

my $TERMINATOR          = "\r\n";
my $send_persistent_cmd = sub {
    my ( $self, $command, $uuid ) = @_;

    $uuid //= Data::UUID->new()->create_str();
    $command = join( ' ', @$command );
    my $actual_cmd = "UUID='$uuid'; echo \"BEGIN \$UUID\"; $command; echo \"___\$?___\"; echo; echo \"EOF \$UUID\"";
    $self->diag("[DEBUG][$self->{'_opts'}{'host'}] EXEC $actual_cmd") if $self->{'_opts'}{'debug'};

    #Use command on bash to ignore stuff like aliases so that we have a minimum level of PEBKAC errors due to aliasing cp to cp -i, etc.
    $self->{'expect'}->print("${actual_cmd}${TERMINATOR}");

    # Rather than take the approach of cPanel, which commands then polls async,
    # it is more straightforward to echo unique strings before and after the command.
    # This made getting the return code somewhat more complicated, as you can see below.
    # That said, it also makes you not have to worry about doing things asynchronously.
    $self->{'expect'}->expect( $self->{'_opts'}{'expect_timeout'}, '-re', qr/BEGIN $uuid/m );
    $self->{'expect'}->expect( $self->{'_opts'}{'expect_timeout'}, '-re', qr/EOF $uuid/m );     # If nothing is printed in timeout, give up

    # Get the actual output, remove terminal grunk
    my $message = $trim->( $self->{'expect'}->before() );
    $message =~ s/[\r\n]{1,2}$//;                                                               # Remove 'secret newline' control chars
    $message =~ s/\x{d}//g;                                                                     # More control chars
    $message = Term::ANSIColor::colorstrip($message);                                           # Strip colors

    # Find the exit code
    my ($code) = $message =~ m/___(\d*)___$/;
    unless ( defined $code ) {

        # Tell the user if they've made a boo-boo
        my $possible_err = $trim->( $self->{'expect'}->before() );
        $possible_err =~ s/\s//g;
        $die_no_trace->("Runaway multi-line string detected.  Please adjust the command passed.") if $possible_err =~ m/\>/;

        $die_no_trace->(
            "Could not determine exit code!
            It timed out (went $self->{'_opts'}{'expect_timeout'}s without printing anything).
            Run command outside of the persistent terminal please."
        );
    }
    $message =~ s/___(\d*)___$//g;

    return ( $message, $code );
};

my $do_persistent_command = sub {
    my ( $self, $command, $no_stderr ) = @_;

    if ( !$self->{'persistent_shell'} ) {
        my ( $pty, $pid ) = $call_ssh_reinit_if_check_fails->( $self, 'open2pty', $self->{'_remote_shell'} );
        die "Got no pty back from open2pty: " . $self->error if !$pty;

        # You might think that the below settings are important.
        # In most cases, they are not.
        $pty->set_raw();
        $pty->stty( 'raw', 'icrnl', '-echo' );
        $pty->slave->stty( 'raw', 'icrnl', '-echo' );

        #Hook in expect
        $self->diag("[DEBUG][$self->{'_opts'}{'host'}] INIT expect on for PTY with pid $pid") if $self->{'_opts'}{'debug'};
        $self->{'expect'} = Expect->init($pty);
        $self->{'expect'}->restart_timeout_upon_receive(1);    #Logabandon by default

        # XXX WARNING bashisms. That said, I'm not sure how to better do this yet portably.
        my $expect_env_cmd = "export PS1=''; export TERM='dumb'; unset HISTFILE; export FOE='configured'; stty raw icrnl -echo; unalias -a; echo \"EOF=\$FOE\"";
        $self->diag("[DEBUG][$self->{'_opts'}{'host'}] EXEC $expect_env_cmd") if $self->{'_opts'}{'debug'};
        $self->{'expect'}->print("${expect_env_cmd}${TERMINATOR}");
        $self->{'expect'}->expect( $self->{'_opts'}{'expect_timeout'}, '-re', qr/EOF=configured/ );
        $self->{'expect'}->clear_accum();

        #cache
        $self->{'persistent_shell'} = $pty;
        $self->{'persistent_pid'}   = $pid;
    }

    #execute the command
    my $uuid = Data::UUID->new()->create_str();
    push @$command, '2>', "/tmp/stderr_$uuid.out" unless $no_stderr;
    my ( $oot, $code ) = $send_persistent_cmd->( $self, $command, $uuid );
    $self->{'_out'} = $oot;

    unless ($no_stderr) {

        #Grab stderr
        ( $self->{'_err'} ) = $send_persistent_cmd->( $self, [ '/usr/bin/cat', "/tmp/stderr_$uuid.out" ] );

        #Clean up
        $send_persistent_cmd->( $self, [ '/usr/bin/rm', '-f', "/tmp/stderr_$uuid.out" ] );
    }

    return int($code);
};

#######################
# END PRIVATE METHODS #
#######################


sub new {
    my ( $class, %opts ) = @_;
    $opts{'host'} = '127.0.0.1' if !$opts{'host'} || $opts{'host'} eq 'localhost';
    $opts{'remote_shell'} ||= 'bash';    # prevent stupid defaults
    $opts{'expect_timeout'} //= 30;      # If your program goes over 30s without printing...

    # Set defaults, check if we can return early
    %opts = ( %defaults, %opts );
    $opts{'_cache_index'} = "$opts{'user'}_$opts{'host'}_$opts{'port'}";
    return $cache{ $opts{'_cache_index'} } unless $opts{'no_cache'} || !$cache{ $opts{'_cache_index'} };

    # Figure out how we're gonna login
    $opts{'_login_method'} = $resolve_login_method->( \%opts );

    # check permissions on base files if we got here
    $check_local_perms->( "$opts{'home'}/.ssh", 0700, 1 ) if -e "$opts{'home'}/.ssh";
    $check_local_perms->( "$opts{'home'}/.ssh/config", 0600 ) if -e "$opts{'home'}/.ssh/config";

    # Make the connection
    my $self = $init_ssh->( $class, \%opts );
    $cache{ $opts{'_cache_index'} } = $self unless $opts{'no_cache'};

    # Stash opts for later
    $self->{'_opts'} = \%opts;

    # Establish persistent shell, etc.
    $post_connect->( $self, \%opts );

    return $self;
}


sub use_persistent_shell {
    my ( $self, $use_shell ) = @_;
    return $self->{'_opts'}{'use_persistent_shell'} if !defined($use_shell);
    return $self->{'_opts'}{'use_persistent_shell'} = $use_shell;
}


sub copy {
    die "Unimplemented, use a subclass of this perhaps?";
}


sub backup_files {
    my ( $self, @files ) = @_;

    # For each file passed in
    foreach my $file (@files) {

        # If the file hasn't already been backed up
        if ( !defined $self->{'file_backups'}{$file} ) {

            # and the file exists
            if ( $self->sftp->test_e($file) ) {

                # then back it up
                $self->{'file_backups'}{$file} = time;
                my $bkup = $file . '.' . $self->{'file_backups'}{$file};
                $self->diag("[INFO] Backing up '$file' to '$bkup'");
                $self->copy( $file, $bkup );    # XXX Probably not that portable, maybe move to Linux.pm somehow?

                # otherwise if the file to be backed up doesn't exist
            }
            else {
                # then just note that a file may need to be deleted later
                $self->{'file_backups'}{$file} = '';
            }
        }
    }
    return;
}


sub restore_files {
    my ( $self, @files ) = @_;

    # If no files were passed in then grab all files that have been backed up
    @files = keys( %{ $self->{'file_backups'} } ) if !@files;

    # foreach file
    foreach my $file (@files) {

        # that has been marked as modified
        if ( defined $self->{'file_backups'}{$file} ) {

            # if a backup exists
            if ( $self->{'file_backups'}{$file} ) {

                # then restore the backup
                my $bkup = $file . '.' . $self->{'file_backups'}{$file};
                if ( $self->sftp->test_e($bkup) ) {
                    $self->diag("[INFO] Restoring backup '$file' from '$bkup'");
                    $self->sftp->rename( $bkup, $file, 'overwrite' => 1 );
                }

                # otherwise no backup exists we just need to delete the modified file
            }
            else {
                $self->diag("[INFO] Deleting '$file' to restore system state (beforehand the file didn't exist)");
                $self->sftp->remove($file);
            }
        }
        delete $self->{'file_backups'}{$file};
    }
    return;
}


sub DESTROY {
    my ($self) = @_;
    return if !$self->{'_perl_pid'} || $$ != $self->{'_perl_pid'} || $disable_destructor;
    $self->restore_files();
    $ENV{SSH_AUTH_SOCK} = $self->{'_opts'}{'_restore_auth_sock'} if $self->{'_opts'}{'_restore_auth_sock'};
    $self->{'persistent_shell'}->close()                         if $self->{'persistent_shell'};

    return $self->SUPER::DESTROY();
}


sub diag {
    my ( $self, @msgs ) = @_;
    print STDOUT "$self->{'_opts'}{'output_prefix'}$_\n" for @msgs;
    return;
}


sub cmd {
    my ($self)  = shift;
    my $opts    = ref $_[0] eq 'HASH' ? shift : {};
    my @command = @_;

    $die_no_trace->( 'No command specified', 'PEBCAK' ) if !@command;

    my $ret;
    $opts->{'use_persistent_shell'} = $self->{'_opts'}{'use_persistent_shell'} if !exists $opts->{'use_persistent_shell'};
    if ( $opts->{'use_persistent_shell'} ) {
        $ret = $do_persistent_command->( $self, \@command, $opts->{'no_stderr'} );
    }
    else {
        $ret = $send->( $self, undef, @command );
    }
    chomp( my $out = $self->{'_out'} );
    my $err = $self->error || '';

    $self->{'last_exit_code'} = $ret;
    return ( $out, $err, $ret );
}


sub cmd_exit_code {
    my ( $self, @args ) = @_;
    return ( $self->cmd(@args) )[2];
}

sub sftp {
    my ($self) = @_;

    unless ( defined $self->{'_sftp'} ) {
        $self->{'_sftp'} = $self->SUPER::sftp();
        die 'Unable to establish SFTP connection to remote host: ' . $self->error() unless defined $self->{'_sftp'};
    }
    return $self->{'_sftp'};
}


sub write {
    my ( $self, $file, $content, $mode, $owner, $group ) = @_;

    die '[PARAMETER] No file specified'          if !defined $file;
    die '[PARAMETER] File content not specified' if !defined $content;

    my %opts;
    $opts{'perm'} = $mode if $mode;
    my $ret = $self->sftp()->put_content( $content, $file, %opts );
    warn "[WARN] Write failed: " . $self->sftp()->error() if !$ret;

    if ( defined $owner || defined $group ) {
        $owner //= $self->{'_opts'}{'user'};
        $group //= $owner;
        $ret = $self->sftp()->chown( $file, $owner, $group );
        warn "[WARN] Couldn't chown $file" if $ret;
    }

    return $ret;
}


sub eval_full {
    my ( $self, %options ) = @_;
    my $code = $options{code};
    my $args = $options{args} // [];
    my $exe  = $options{exe} || '/usr/bin/perl';

    require Storable;
    local $Storable::Deparse = 1;

    my ( $in_fh, $out_fh, undef, $pid ) = $call_ssh_reinit_if_check_fails->(
        $self,
        'open_ex',
        { stdin_pipe => 1, stdout_pipe => 1, stderr_to_stdout => 1 },
        q{export PERLCODE='use Storable;$Storable::Eval=1;my $input;while ($input .= <STDIN>) { if ($input =~ /\d+START_STORABLE(.*)STOP_STORABLE\d+/) { my @result = eval { my $in_hr = Storable::thaw(pack("H*", $1)); if ( ref $in_hr->{code} ) { return $in_hr->{wantarray} ? $in_hr->{code}->(@{$in_hr->{args}}) : scalar $in_hr->{code}->(@{$in_hr->{args}});} return $in_hr->{wantarray} ? eval $in_hr->{code} : scalar eval $in_hr->{code};};  print $$ . "START_STORABLE" . unpack("H*", Storable::freeze( { data => \@result, error => "$@" })) . "STOP_STORABLE" . $$ . "\n";exit;}}'; }
          . $exe
          . q{ -e "$PERLCODE";}
    );

    die "Failed to connect: $!" unless ($pid);
    print $in_fh $$ . "START_STORABLE" . unpack( "H*", Storable::freeze( { code => $code, args => $args, wantarray => wantarray() } ) ) . "STOP_STORABLE" . $$ . "\n";
    close $in_fh;

    my $output = '';
    while ( $out_fh->sysread( $output, 4096, length($output) ) > 0 ) {
        1;
    }
    close $out_fh;
    waitpid( $pid, 0 );

    my $result = { error => "Unable to deserialize output from remote_eval: $output" };
    if ( $output =~ /\d+START_STORABLE(.*)STOP_STORABLE\d+/ ) {
        $result = Storable::thaw( pack( "H*", $1 ) );
    }

    die $result->{error} if ( $result->{error} );

    return wantarray ? @{ $result->{data} } : $result->{data}[0];
}


sub cmd_stream {
    my ( $self, @cmd ) = @_;
    my $line_reader = sub {
        my ( $self, $out, $stash_param ) = @_;
        $out =~ s/[\r\n]{1,2}$//;
        $self->diag($out);
        $self->{$stash_param} .= "$out\n";

        return;
    };
    return $send->( $self, $line_reader, @cmd );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OpenSSH::More - Net::OpenSSH submodule with many useful features

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use Net::OpenSSH::More;
    my $ssh = Net::OpenSSH::More->new(
		'host'     => 'some.host.test',
		'port'     => 69420,
        'user'     => 'azurediamond',
        'password' => 'hunter2',
    );
    ...

=head1 DESCRIPTION

Submodule of Net::OpenSSH that contains many methods that were
otherwise left "as an exercise to the reader" in the parent module.
Highlights:
* Persistent terminal via expect for very fast execution, less forking.
* Usage of File::Temp and auto-cleanup to prevent lingering ctl_path cruft.
* Ability to manipulate incoming text while streaming the output of commands.
* Run perl subroutine refs you write locally but execute remotely.
* Many shortcut methods for common system administration tasks
* Registration method for commands to run upon DESTROY/before disconnect.
* Automatic reconnection ability upon connection loss

=head1 NAME

Net::OpenSSH::More

=head1 METHODS

=head2 new

Instantiate the object, establish the connection. Note here that I'm not allowing
a connection string like the parent module, and instead exploding these out into
opts to pass to the constructor. This is because we want to index certain things
under the hood by user, etc. and I *do not* want to use a regexp to pick out
your username, host, port, etc. when this problem is solved much more easily
by forcing that separation on the caller's end.

ACCEPTS:
* %opts - <HASH> A hash of key value pairs corresponding to the what you would normally pass in to Net::OpenSSH,
  along with the following keys:
  * use_persistent_shell - Whether or not to setup Expect to watch a persistent TTY. Less stable, but faster.
  * expect_timeout - When the above is active, how long should we wait before your program prints something
    before bailing out?
  * no_agent - Pass in a truthy value to disable the SSH agent. By default the agent is enabled.
  * die_on_drop - If, for some reason, the connection drops, just die instead of attempting reconnection.
  * output_prefix - If given, is what we will tack onto the beginning of any output via diag method.
    useful for streaming output to say, a TAP consumer (test) via passing in '# ' as prefix.
  * debug - Pass in a truthy value to enable certain diag statements I've added in the module and pass -v to ssh.
  * home - STRING corresponding to an absolute path to something that "looks like" a homedir. Defaults to the user's homedir.
    useful in cases where you say, want to load SSH keys from a different path without changing assumptions about where
    keys exist in a homedir on your average OpenSSH using system.
  * no_cache - Pass in a truthy value to disable caching the connection and object, indexed by host string.
    useful if for some reason you need many separate connections to test something. Make sure your MAX_SESSIONS is set sanely
    in sshd_config if you use this extensively.
  * retry_interval - In the case that sshd is not up on the remote host, how long to wait while before reattempting connection.
    defaults to 6s. We retry $RETRY_MAX times, so this means waiting a little over a minute for SSH to come up by default.
	If your situation requires longer intervals, pass in something longer.
  * retry_max - Number of times to retry when a connection fails. Defaults to 10.

RETURNS a Net::OpenSSH::More object.

=head3 A note on Authentication order

We attempt to authenticate using the following details, and in this order:
1) Use supplied key_path.
2) Use supplied password.
3) Use existing SSH agent (SSH_AUTH_SOCK environment variable)
4) Use keys that may exist in $HOME/.ssh - id_rsa, id_dsa and id_ecdsa (in that order).

If all methods therein fail, we will die, as nothing will likely work at that point.
It is important to be aware of this if your remove host has something like fail2ban or cPHulkd
enabled which monitors and blocks access based on failed login attempts. If this is you,
ensure that you have not configured things in a way as to accidentally lock yourself out
of the remote host just because you fatfingered a connection detail in the constructor.

=head2 use_persistent_shell

Pass "defined but falsy/truthy" to this to enable using the persistent shell or deactivate its' use.
Returns either the value you just set or the value it last had (if arg is not defined).

=head2 copy

Copies $SOURCE file on the remote machine to $DEST on the remote machine.
If you want to sync/copy files from remote to local or vice/versa, use
the sftp accessor (Net::SFTP::Foreign) instead.

Dies in this module, as this varies on different platforms (GNU/LINUX, Windows, etc.)

=head2 B<backup_files (FILES)>

Backs up files which you wish to later restore to their original state. If the file does
not currently exist then the method will still store a reference for later file deletion.
This may seem strange at first, but think of it in the context of preserving 'state' before
a test or scripted action is run. If no file existed prior to action, the way to restore
that state would be to delete the added file(s).

NOTE: Since copying files on the remote system to another location on the remote system
is in fact not something implemented by Net::SFTP::Foreign, this is necessarily going
to be a "non-portable" method -- use the Linux.pm subclass of this if you want to be able
to actually backup files without dying, or subclass your own for Windows, however they
choose to implement `copy` with their newfangled(?) SSH daemon.

C<FILES> - LIST - File(s) to backup.

C<STASH> - BOOL - mv files on backup instead of cp.  This will make sure FILES arg path no
                  longer exists at all so a fresh FILE can be written during run.

my $file = '/path/to/file.txt';
$ssh->backup_files($file);

my @files = ( '/path/to/file.txt', '/path/to/file2.txt' );
$ssh->backup_files(@files);

=head2 B<restore_files (FILES)>

Restores specific file(s) backed up using backup_files(), or all the backup files if none
are specified, to their previous state.

If the file in question DID NOT exist when backup_files was last invoked for the file,
then the file will instead be deleted, as that was the state of the file previous to
actions taken in your test or script.

C<FILES> - (Optional) - LIST - File(s) to restore.

my $file = '/path/to/file.txt';
$ssh->backup_files($file);
$ssh->restore_files();

=head2 DESTROY

Noted in POD only because of some behavior differences between the
parent module and this. The following actions are taken *before*
the parent's destructor kicks in:
* Return early if you aren't the PID which created the object.
* Restore any files backed up with backup_files earlier.

=head2 diag

Print a diagnostic message to STDOUT.
Optionally prefixed by what you passed in as $opts{'output_prefix'} in the constructor.
I use this in several places when $opts{'debug'} is passed to the constructor.

ACCEPTS LIST of messages.

RETURNS undef.

=head2 cmd

Execute specified command via SSH. If first arg is HASHREF, then it uses that as options.
Command is specifed as a LIST, as that's the easiest way to ensure escaping is done correctly.

$opts HASHREF:
C<no_stderr> - Boolean - Whether or not to discard STDERR.
C<use_operistent_shell> - Boolean - Whether or not to use the persistent shell.

C<command> - LIST of components combined together to make a shell command.

Returns LIST STDOUT, STDERR, and exit code from executed command.

    my ($out,$err,$ret) = $ssh->cmd(qw{ip addr show});

If use_persistent_shell was truthy in the constructor (or you override via opts HR),
then commands are executed in a persistent Expect session to cut down on forks,
and in general be more efficient.

However, some things can hang this up.
Unterminated Heredoc & strings, for instance.
Also, long running commands that emit no output will time out.
Also, be careful with changing directory;
this can cause unexpected side-effects in your code.
Changing shell with chsh will also be ignored;
the persistent shell is what you started with no matter what.
In those cases, use_persistent_shell should be called to disable that before calling this.
Also note that persistent mode basically *requires* you to use bash.
I am not yet aware of how to make this better yet.

If the 'debug' opt to the constructor is set, every command executed hereby will be printed.

If no_stderr is passed, stderr will not be gathered (it takes writing/reading to a file, which is additional time cost).

BUGS:

In no_persist mode, stderr and stdout are merged, making the $err parameter returned less than useful.

=head2 cmd_exit_code

Same thing as cmd but only returns the exit code.

=head3 B<write (FILE,CONTENT,[MOD],[OWN])>

Write a file.

C<FILE> - Absolute path to file.
C<CONTENT> - Content to write to file.
C<MOD> - File mode.
C<OWN> - File owner. Defaults to the user you connected as.
C<GRP> - File group. Defaults to OWN.

Returns true if all actions are successful, otherwise warn/die about the error.

    $ssh->write($filename,$content,'600','root');

=head3 B<eval_full( options )>

Run Perl code on the remote system and return the results.
interpreter defaults to /usr/bin/perl.

B<Input>

Input options are supplied as a hash with the following keys:

    code - A coderef or string to execute on the remote system.
    args - An optional arrayref of arguments to the code.
    exe  - Path to perl executable. Optional.

B<Output>

The output from eval_full() is based on the return value of the input
coderef. Return context is preserved for the coderef.

All error states will generate exceptions.

B<Caveats>

A coderef supplied to this function will be serialized by B::Deparse
and recreated on the remote server. This method of moving the code does
not support closing over variables, and any needed modules must
be loaded inside the coderef with C<require>.

B<Example>

    my $greeting_message = $ssh->eval_full( code => sub { return "Hello $_[0]";}, args => [$name] );

=head3 cmd_stream

Pretty much the same as running cmd() with one important caveat --
all output is formatted with the configured prefix and *streams* to STDOUT.
Useful for remote test harness building.
Returns (exit_code), as in this context that should be all you care about.

You may be asking, "well then why not use system?" That does not support
the prefixing I'm doing here. Essentially we provide a custom line reader
to 'send' which sends the output to STDOUT via 'diag' as well as doing
the "default" behavior (append the line to the relevant output vars).

NOTE: This uses send() exclusively, and will never invoke the persistent shell,
so if you want that, don't use this.

=head1 SPECIAL THANKS

cPanel, L.L.C. - in particularly the QA department (which the authors once were in).
Many of the ideas for this module originated out of lessons learned from our time
writing a ssh based remote teststuite for testing cPanel & WHM.

Chris Eades - For the original module this evolved from at cPanel over the years.

bdraco (Nick Koston) - For optimization ideas and the general process needed for expect & persistent shell.

J.D. Lightsey - For the somewhat crazy looking but nonetheless very useful eval_full subroutine used
to execute subroutine references from the orchestrating server on the remote host's perl.

Brian M. Carlson - For the highly useful sftp shortcut method that caches Net::SFTP::Foreign.

Rikus Goodell - For shell escaping expertise

=head1 IN MEMORY OF

Paul Trost
Dan Stewart

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::OpenSSH|Net::OpenSSH>

=item *

L<Net::OpenSSH::More::Linux|Net::OpenSSH::More::Linux>

=back

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 CONTRIBUTORS

=for stopwords Andy Baugh teo

=over 4

=item *

Andy Baugh <andy@troglodyne.net>

=item *

teo <Andy Baugh>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
