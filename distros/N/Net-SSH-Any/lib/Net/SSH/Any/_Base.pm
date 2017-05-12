package Net::SSH::Any::_Base;

use strict;
use warnings;
use Carp;

use File::Spec;
use Scalar::Util ();
use Encode ();

use Net::SSH::Any::Constants qw(SSHA_BACKEND_ERROR SSHA_LOCAL_IO_ERROR SSHA_UNIMPLEMENTED_ERROR SSHA_ENCODING_ERROR);
use Net::SSH::Any::Util;
our @CARP_NOT = qw(Net::SSH::Any::Util);

sub _new {
    my ($class, $opts) = @_;
    my $os = delete $opts->{os};

    my (%remote_cmd, %local_cmd, %remote_extra_args, %local_extra_args);
    for (keys %$opts) {
        /^remote_(.*)_cmd$/ and $remote_cmd{$1} = $opts->{$_};
        /^local_(.*)_cmd$/ and $local_cmd{$1} = $opts->{$_};
        /^remote_(.*)_extra_args$/ and $remote_extra_args{$1} = $opts->{$_};
        /^local_(.*)_extra_args$/ and $local_extra_args{$1} = $opts->{$_};
    }

    my $relaxed_command_lookup = delete $opts->{relaxed_command_lookup};

    my $self = { os => $os,
                 error => 0,
                 error_prefix => [],
                 backend_log => [],
                 remote_cmd => \%remote_cmd,
                 local_cmd => \%local_cmd,
                 remote_extra_args => \%remote_extra_args,
                 local_extra_args => \%local_extra_args,
                 relaxed_cmd_lookup => $relaxed_command_lookup,
               };

    my $encoding = $self->{encoding} = delete $opts->{encoding} // 'utf8';
    $self->{stream_encoding} = delete $opts->{stream_encoding} // $encoding;
    $self->{argument_encoding} = delete $opts->{argument_encoding} // $encoding;

    bless $self, $class;
    $self;
}

sub _log_error_and_reset_backend {
    my $self = shift;
    push @{$self->{backend_log}}, "$self->{backend}: [".($self->{error}+0)."] $self->{error}";
    $self->{error} = 0;
    delete $self->{backend};
    delete $self->{backend_module};
    ()
}

sub _load_backend_module {
    my ($self, $class, $backend, $required_version) = @_;
    $backend =~ /^\w+$/ or croak "Bad backend name '$backend' for class '$class'";
    $self->{backend} = $backend;
    my $module = $self->{backend_module} = "${class}::Backend::${backend}";

    local ($@, $SIG{__DIE__});
    my $ok = eval <<EOE;
no strict;
no warnings;
require $module;
1;
EOE
    if ($ok) {
        if ($required_version) {
            if ($module->can('_backend_api_version')) {
                my $version = $module->_backend_api_version;
                if ($version >= $required_version) {
                    return 1;
                }
                else {
                    $self->_set_error(SSHA_BACKEND_ERROR,
                                     "backend API version $version is too old ($required_version required)");
                }
            }
            else {
                $self->_set_error(SSHA_BACKEND_ERROR, 'method _backend_api_version missing');
            }
        }
        else {
            return 1;
        }
    }
    else {
        $self->_set_error(SSHA_BACKEND_ERROR, "unable to load module '$module'", $@);
    }

    $self->_log_error_and_reset_backend;
    ()
}

sub error { shift->{error} }

sub die_on_error {
    my $self = shift;
    $self->{error} and croak(join(': ', @_, "$self->{error}"));
    1;
}

sub _set_error {
    my $self = shift;
    my $code = shift || 0;
    my @msg = grep { defined && length } @_;
    @msg = "Unknown error $code" unless @msg;
    my $error = $self->{error} = ( $code
                                  ? Scalar::Util::dualvar($code, join(': ', @{$self->{error_prefix}}, @msg))
                                  : 0 );
    $debug and $debug & 1 and _debug "set_error($code - $error)";
    return $error
}

sub _or_set_error {
    my $self = shift;
    $self->{error} or $self->_set_error(@_);
}

sub _or_check_error_after_eval {
    if ($@) {
        my ($any, $code) = @_;
        unless ($any->{error}) {
            my $err = $@;
            $err =~ s/(.*) at .* line \d+.$/$1/;
            $any->_set_error($code, $err);
        }
        return 0;
    }
    1
}

sub _open_file {
    my ($self, $def_mode, $name_or_args) = @_;
    my ($mode, @args) = (ref $name_or_args
			 ? @$name_or_args
			 : ($def_mode, $name_or_args));
    if (open my $fh, $mode, @args) {
        return $fh;
    }
    $self->_set_error(SSHA_LOCAL_IO_ERROR, "Unable to open file '@args': $!");
    return undef;
}

my %loaded;
sub _load_module {
    my ($self, $module) = @_;
    $loaded{$module} ||= eval "require $module; 1" and return 1;
    $self->_set_error(SSHA_UNIMPLEMENTED_ERROR, "Unable to load perl module $module");
    return;
}

sub _load_os {
    my $self = shift;
    my $os = $self->{os} //= ($^O =~ /^mswin/i ? 'MSWin' : 'POSIX');
    my $os_module = "Net::SSH::Any::OS::$os";
    $self->_load_module($os_module) or return;
    $self->{os_module} = $os_module;
}

sub _find_cmd_by_friend {
    my ($any, $name, $friend) = @_;
    if (defined $friend) {
        my $up = File::Spec->updir;
        my ($drive, $dir) = File::Spec->splitpath($friend);
        my $base = File::Spec->catpath($drive, $dir);
        for my $path (File::Spec->join($base, $name),
                      map File::Spec->join($base, $up, $_, $name), qw(bin sbin libexec) ) {
            my $cmd = $any->_os_validate_cmd($path);
            return $cmd if defined $cmd;
        }
    }
    ()
}

sub _find_cmd_in_path {
    my ($any, $name) = @_;
    for my $path (File::Spec->path) {
        my $cmd = $any->_os_validate_cmd(File::Spec->join($path, $name));
        return $cmd if defined $cmd;
    }
    ()
}

sub _find_cmd {
    my $any = shift;
    my $opts = (ref $_[0] ? shift : {});
    my ($name, $friend, $app, $default) = @_;
    my $safe_name = $name;
    $safe_name =~ s/\W/_/g;
    my $cmd = ( $any->{local_cmd}{$safe_name}             //
                $any->_find_cmd_by_friend($name, $friend) //
                $any->_find_cmd_in_path($name)            //
                $any->_find_helper_cmd($name)             //
                $any->_os_find_cmd_by_app($name, $app)    //
                $any->_os_validate_cmd($default) );
    return $cmd if defined $cmd;
    return $name if $opts->{relaxed} or $any->{relaxed_cmd_lookup};
    $any->_or_set_error(SSHA_BACKEND_ERROR, "Unable to find command '$name'");
    ()
}

sub _find_helper_cmd {
    my ($any, $name) = @_;
    $debug and $debug & 1024 and _debug "looking for helper $name";
    my $module = my $last = $any->{backend_module} // return;
    $last =~ s/.*::// or return;
    $module =~ s{::}{/}g;
    $debug and $debug & 1024 and _debug "module as \$INC key is ", $module, ".pm";
    my $file_pm = $INC{"$module.pm"} // return;
    my ($drive, $dir) = File::Spec->splitpath(File::Spec->rel2abs($file_pm));
    my $path = File::Spec->catpath($drive, $dir, $last, 'Helpers', $name);
    $any->_os_validate_cmd($path);
}

sub _find_local_extra_args {
    my ($any, $name, $opts, @default) = @_;
    my $safe_name = $name;
    $safe_name =~ s/\W/_/g;
    my $extra = ( $opts->{"local_${safe_name}_extra_args"} //
                  $any->{local_extra_args}{$safe_name} //
                  \@default );
    [_array_or_scalar_to_list $extra]
}

my %posix_shell = map { $_ => 1 } qw(POSIX bash sh ksh ash dash pdksh mksh lksh zsh fizsh posh);

sub _new_quoter {
    my ($any, $shell) = @_;
    if ($posix_shell{$shell}) {
	$any->_load_module('Net::SSH::Any::POSIXShellQuoter') or return;
	return 'Net::SSH::Any::POSIXShellQuoter';
    }
    else {
	$any->_load_module('Net::OpenSSH::ShellQuoter') or return;
	return Net::OpenSSH::ShellQuoter->quoter($shell);
    }
}

sub _quoter {
    my ($any, $shell) = @_;
    defined $shell or croak "shell argument is undef";
    return $any->_new_quoter($shell);
}

sub _quote_args {
    my $any = shift;
    my $opts = shift;
    ref $opts eq 'HASH' or die "internal error";
    my $quote = delete $opts->{quote_args};
    my $glob_quoting = delete $opts->{glob_quoting};
    my $argument_encoding =  $any->_delete_argument_encoding($opts);
    $quote = (@_ > 1) unless defined $quote;

    my @quoted;
    if ($quote) {
	my $shell = delete $opts->{remote_shell} // delete $opts->{shell};
	my $quoter = $any->_quoter($shell) or return;
	my $quote_method = ($glob_quoting ? 'quote_glob' : 'quote');

        # foo   => $quoter
        # \foo  => $quoter_glob
        # \\foo => no quoting at all and disable extended quoting as it is not safe
        for (@_) {
            if (ref $_) {
                if (ref $_ eq 'SCALAR') {
                    push @quoted, $quoter->quote_glob($$_);
                }
                elsif (ref $_ eq 'REF' and ref $$_ eq 'SCALAR') {
                    push @quoted, $$$_;
                }
                else {
                    croak "invalid reference in remote command argument list"
                }
            }
            else {
                push @quoted, $quoter->$quote_method($_);
            }
        }
    }
    else {
        croak "reference found in argument list when argument quoting is disabled" if (grep ref, @_);
        @quoted = @_;
    }
    $any->_encode_args($argument_encoding, @quoted);
    $debug and $debug & 1024 and _debug("command+args: @quoted");
    wantarray ? @quoted : join(" ", @quoted);
}

sub _delete_argument_encoding {
    my ($any, $opts) = @_;
    _first_defined(delete $opts->{argument_encoding},
                   delete $opts->{encoding},
                   $any->{argument_encoding})
}

sub _delete_stream_encoding {
    my ($any, $opts) = @_;
    _first_defined(delete $opts->{stream_encoding},
                   $opts->{encoding},
                   $any->{stream_encoding})
}

sub _find_encoding {
    my ($any, $encoding, $data) = @_;
    my $enc = Encode::find_encoding($encoding)
        or $any->_or_set_error(SSHA_ENCODING_ERROR, "bad encoding '$encoding'");
    return $enc
}

sub _encode_data {
    my $any = shift;
    my $encoding = shift;
    if (@_) {
        my $enc = $any->_find_encoding($encoding) or return;
        local $any->{error_prefix} = [@{$any->{error_prefix}}, "data encoding failed"];
        local ($@, $SIG{__DIE__});
        eval { defined and $_ = $enc->encode($_, Encode::FB_CROAK()) for @_ };
        $any->_or_check_error_after_eval(SSHA_ENCODING_ERROR) or return;
    }
    1
}

sub _decode_data {
    my $any = shift;
    my $encoding = shift;
    my $enc = $any->_find_encoding($encoding) or return;
    if (@_) {
        local ($@, $SIG{__DIE__});
        eval { defined and $_ = $enc->decode($_, Encode::FB_CROAK()) for @_ };
        $any->_or_check_error_after_eval(SSHA_ENCODING_ERROR) or return;
    }
    1;
}

sub _encode_args {
    if (@_ > 2) {
        my $any = shift;
        my $encoding = shift;
        local $any->{error_prefix} = [@{$any->{error_prefix}}, "argument encoding failed"];
        if (my $enc = $any->_find_encoding($encoding)) {
            $any->_encode_data($enc, @_);
        }
        return !$any->{_error};
    }
    1;
}

# transparently delegate method calls to backend and os packages:
sub AUTOLOAD {
    our $AUTOLOAD;
    my ($name) = $AUTOLOAD =~ /([^:]*)$/;
    my $sub;
    no strict 'refs';
    if (my ($os_name) = $name =~ /^_os_(.*)/) {
        $sub = sub {
            my $os = $_[0]->{os_module} //= $_[0]->_load_os or return;
            my $method = $os->can($os_name)
                or croak "method '$os_name' not defined in OS '$os'";
            goto &$method;
        };
    }
    else {
        $sub = sub {
            my $module = $_[0]->{backend_module} or return;
            my $method = $module->can($name)
                or croak "method '$name' not defined in backend '$module'";
            goto &$method;
        };
    }
    *{$AUTOLOAD} = $sub;
    goto &$sub;
}

sub DESTROY {
    my $self = shift;
    my $module = $self->{backend_module};
    if (defined $module) {
        my $sub = $module->can('DESTROY');
        $sub->($self) if $sub;
    }
}

1;
