package Net::SSH::Any::Autodetector;

use strict;
use warnings;

use Net::SSH::Any::Util qw($debug _debug _array_or_scalar_to_list);

my @default_tests = qw(os shell uname_all);

sub _new {
    my ($class, $any, $opts, @tests) = @_;
    @tests = @default_tests unless @tests;
    $opts->{apply} //= 1;
    my $self = { any => $any,
                 opts => $opts,
                 results => {},
                 acu => { tests_done => [] },
                 tests => \@tests};
    bless $self, $class;
}

sub run {
    my $self = shift;
    $self->_run_test($_) for @{$self->{tests}};
    $self->{any}->_set_error;
    $self->{acu};
}

sub _lookup_test {
    my ($self, $test) = @_;
    if (my $sub = $self->can("_test_$test")) {
        return $sub
    }

    if ($test =~ /^uname_(.*)$/) {
        return sub { shift->_test_uname($1) }
    }
    undef
}

sub _run_test {
    my ($self, $test) = @_;
    my $ok = $self->{result}{$test} //= do {
        $debug and $debug & 65536 and _debug("running test $test");
        my $result;
        if (my $method = $self->_lookup_test($test)) {
            if ($result = $self->$method) {
                @{$self->{acu}}{keys %$result} = values %$result;
                $result->{ok} //= 1;
            }
            else {
                $result = { ok => 0 }
            }
        }
        push @{$self->{acu}{tests_done}}, $test;
        $result;
    }->{ok};
    $ok ? 1 : undef;
}

sub _try_cmd {
    my ($self, $cmd) = @_;
    my $any = $self->{any};
    my $out = $any->capture({stderr_discard => 1}, $cmd);
    return if $any->error or not defined $out or $out !~ /\S/;
    $out =~ s/^\s+//; $out =~ s/\s+$//;
    if (wantarray) {
        return split /\s*[\n\r]+\s*/, $out;
    }
    chomp($out);
    $out
}

sub _find_remote_cmd {
    my ($self, $cmd) = @_;
    # FIXME: be clever!
    return $cmd;
}

sub _capture {
    my ($self, $key, $cmd) = @_;
    my @key = _array_or_scalar_to_list $key;

    my $head = $self->{acu}{capture} //= {};
    while (1) {
        my $key = shift @key;
        if (@key) {
            $head = ($head->{$key} //= {})
        }
        else {
            $head->{$key} = $self->_try_cmd($cmd)
                unless exists $head->{$key};
            return $head->{$key};
        }
    }
}

my %uname_flag2long = ( -a => 'all',
                        -s => 'kernel_name',
                        -n => 'nodename',
                        -v => 'kernel_version',
                        -m => 'machine',
                        -p => 'processor',
                        -i => 'hardware_platform',
                        -o => 'operating_system' );

my %uname_long2flag = reverse %uname_flag2long;

sub _capture_uname {
    my $self = shift;
    my $long = shift;
    my $flag = $uname_long2flag{$long};
    $self->_capture([uname => $long], "uname $flag");
}

sub _test_uname {
    my ($self, $name) = @_;
    my $any = $self->{any};
    my @keys = (defined($name) ? $name : keys %uname_long2flag);
    $self->_capture_uname($_) for @keys;
    {}
}

sub _test_os_windows {
    my $self = shift;
    my $out = $self->_capture([windows_cmd => 'ver'], 'cmd /c ver') // return;
    $out =~ /\b(Microsoft\s+Windows)\b(?:\s+\[Version\s+([^\s\]]+)\])?/i or return;
    { windows => $1, windows_version => $2 }
}

sub _test_posix_env_shell {
    my $self = shift;
    $self->_run_test('os_posix') // return;
    my $out = $self->_capture([env => 'SHELL'], 'echo $SHELL') // return;
    { shell => $out }
}

sub _test_os {
    my $self = shift;
    $self->_run_test('os_posix') and return {};
    $self->_run_test('os_windows') and return {};
    ()
}

sub _test_os_posix {
    my $self = shift;
    my $os = $self->_capture_uname('operating_system') //
        $self->_capture_uname('kernel_name') // return;
    { os => $os, posix => 1 };
}

sub _test_shell {
    my $self = shift;
    $self->_run_test('posix_env_shell') // return;
    my $shell = $self->{acu}{shell} // return;
    $shell =~ s|.*/|| // return;
    $self->{any}{remote_shell} = $shell
        if $self->{opts}{apply};
    my $csh_shell = $shell =~ (/\bt?csh$/);
    { csh_shell => $csh_shell }
}

sub _test_linux_os_release {
    my $self = shift;
    $self->_run_test('os_linux') // return;
    my $cat = $self->_find_remote_cmd('cat');
    if (my @out = $self->_try_cmd("$cat /etc/os-release")) {
        my %output;
        for (@out) {
            $output{$1} = $2 if /^(\w+)\s*=\s*(.*?)\s*$/;
        }
        return { os_release => \%output }
    }
    ()
}

1;
