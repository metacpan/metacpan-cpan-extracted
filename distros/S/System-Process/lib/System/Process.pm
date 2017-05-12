package System::Process;

=head1 NAME

System::Process

=head1 DESCRIPTION

Manipulate system process as perl object. This is a simple wrapper over ps on
*nix systems. For Windows systems - under construction.

=head1 SYNOPSIS

    use System::Process;

    my $process_object = pidinfo pid => 5321;
    if ($process_object) {
        print $process_object->command();
    }

=head1 METHODS

=over

=item B<pidinfo>

pidinfo(%)

params is hash (pid=>4444) || (file=>'/path/to/pid/file' || pattern => 'my\scool\sname')

returns System::Process::Unit object that supports following methods if pid or file option specified.
If pattern option specified - returns arrayref of System::Process objects.

=back

=head1 PROCESS OBJECT METHODS

If your ps uax header simillar to my:
    USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
You will get these methods:

=over

=item B<cpu>

Returns %CPU.

=item B<time>

Returns TIME.

=item B<stat>

Returns STAT.

=item B<tty>

Returns TTY.

=item B<user>

Returns USER

=item B<mem>

Returns %MEM

=item B<rss>

Returns %RSS

=item B<vsz>

Returns VSZ

=item B<command>

Returns COMMAND

=item B<start>

Returns START

=item B<pid>

Returns PID

=back

Anyway, you will get methods named as lowercase header values.

=over 

=item B<cankill>

Checks possibility of 'kill' process.
Returns 1 if possible

=item B<kill>

Kills a process with specified signal
    $process_object->kill(9);

=item B<refresh>

Refreshes data for current pid.

=item B<write_pid>

Writes pid to desired file.
    $process_object->write_pid('/my/pid/path');

=item B<is_alive>

Returns true if process alive.

=back

=cut


use strict;
use warnings;

no warnings qw/once/;

use Carp;
use POSIX;

our $VERSION = 0.19;
our $ABSTRACT = "Simple OO wrapper over ps.";
our $TEST = 0;

sub import {
    my ($class, $import) = @_;

    if ($import && $import =~ m/test/s) {
        $TEST = 1;
        $System::Process::Unit::TEST = 1;
    }

    if ($^O =~ m/MSWin32/is) {
        croak "Not implemented for windows yet.";
    }
    *{main::pidinfo} = \&pidinfo;
}


sub pidinfo {
    my (%params, $pid);

    if (scalar @_ & 1) {
        %params = (
            pid  =>  shift
        );
    }
    else {
        %params = @_;    
    }
    
    if ($params{pid} && $params{file}) {
        croak 'Choose one';
    }

    if (!$params{pid} && !$params{file} && !$params{pattern}) {
        croak 'Missing pid or file param';
    }

    if ($params{file}) {
        return undef unless -r $params{file};

        open PID, $params{file};
        $pid = <PID>;
        close PID;
        return undef unless $pid;
        chomp $pid;
    }
    elsif ($params{pattern}) {
        return System::Process::Unit->new_bundle($params{pattern});

    }
    else {
        $pid = $params{pid};
    }
    
    if ($pid !~ m/^\d+$/s) {
        croak "PID must be a digits sequence";
    }
    
    if ($pid > POSIX::UINT_MAX) {
        croak "PID value ($pid) is too big";
    }

    return System::Process::Unit->new($pid);
}


1;

package System::Process::Unit;
use strict;
use warnings;
use Carp;

our $TEST = 0;
our $AUTOLOAD;

my @allowed_subs = qw/
    cpu
    time
    stat
    tty
    user
    mem
    rss
    vsz
    command
    start
/;

my $hal;
%$hal = map {(__PACKAGE__ . '::' . $_, 1)} @allowed_subs;


sub AUTOLOAD {
    my $program = $AUTOLOAD;

    croak "Undefined subroutine $program" unless $hal->{$program};

    my $sub = sub {
        my $self = shift;
        return $self->internal_info($program);
    };
    no strict 'refs';
    *{$program} = $sub;
    use strict 'refs';
    goto &$sub;
}


sub new {
    my ($class, $pid) = @_;

    my $self = {};
    bless $self, $class;
    $self->pid($pid);
    unless ($self->process_info()) {
        return undef;
    }

    return $self;
}


sub new_bundle {
    my ($class, $pattern) = @_;

    return get_bundle($class, $pattern);
}


sub refresh {
    my $self = shift;
    my $pid = $self->pid();

    $self = System::Process::pidinfo(pid     =>  $pid);
    return 1;
}


sub process_info {
    my $self = shift;

    my $command = 'ps u ' . $self->pid();
    my @res = `$command`;
    my $parse_result = parse_output(@res);

    # return $self->parse_output(@res);

    return $parse_result unless $parse_result;

    $self->internal_info($parse_result);
    return 1;
}


sub get_bundle {
    my ($class, $pattern) = @_;

    my $command = qq/ps uax/;
    my @res;

    if ($TEST) {
        @res = (
            'PID CPU USER COMMAND',
            '65532 123 test_user blahblahblah',
            '65533 123 test_user blahblahblah',
            '65531 123 root rm -rf',
            '65534 123 test_user blahblahblah',
        );
    }
    else {
        @res = `$command`;
    }

    my $header = shift @res;

    @res = grep {
        if (m/$pattern/s) {
            1;
        }
        else {
            0;
        }
    } map {
        s/\s*$//;
        $_;
    } @res;

    return [] unless scalar @res;

    my $bundle = [];

    for my $r (@res) {
        my $res = parse_output($header, $r);
        my $object = {
            pid         =>  $res->{pid},
            _procinfo   =>  $res,
        };

        bless $object, $class;
        push @$bundle, $object;
    }
    return $bundle;
}


sub write_pid {
    my ($self, $file) = @_;

    return 0 unless $self->pid();
    open PID, '>', $file or return 0;

    print PID $self->pid() or return 0;

    close PID;
    return 1;
}


sub parse_n_generate {
    my ($self, @params) = @_;

    my $res = parse_output(@params);
    $self->internal_info($res);
    return 1;
}


sub parse_output {
    if (ref $_[0] eq __PACKAGE__) {
        shift;
    }

    my (@out) = @_;

    return 0 unless $out[1];

    my @header = split /\s+/, $out[0];
    my @values = split /\s+/, $out[1];
    my $res;

    my $last_key;

    for (0 .. $#values) {
        unless (@header) {
            unshift @values, $res->{$last_key};
            $res->{$last_key} = join ' ', @values;
            last;
        }
        else {
            my $k = $last_key = shift @header;
            my $v = shift @values;
            $res->{$k} = $v;
        }
    }

    for my $key (keys %$res) {
        my $k2 = lc $key;
        $k2 =~ s/[^A-Za-z]//gs;
        $res->{$k2} = delete $res->{$key};
    }
    
    return $res;
}


sub pid {
    my ($self, $pid) = @_;

    if ($pid) {
        $self->{pid} = $pid;
    }
    return $self->{pid};
}


sub internal_info {
    my ($self, $param) = @_;

    if (ref $param eq 'HASH') {
        $self->{_procinfo} = $param;
        return 1;
    }
    else {
        $param =~ s|^.+::||;
        return $self->{_procinfo}->{$param};
    }
}


sub cankill {
    my $self = shift;

    my $pid = $self->pid();

    if (kill 0, $pid) {
        return 1;
    }
    return 0;
}


sub is_alive {
    my ($self) = @_;
    
    $self->refresh();
    return $self->cankill();
}

sub kill {
    my ($self, $signal) = @_;

    if (!defined $signal) {
        croak 'Signal must be specified';
    }
    return kill $signal, $self->pid();
}


sub DESTROY {
    my $self = shift;
    undef $self;
}


1;

__END__;

