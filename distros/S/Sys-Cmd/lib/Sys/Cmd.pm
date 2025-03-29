use v5.18;

package Sys::Cmd;
use warnings;
no warnings "experimental::lexical_subs";
use feature 'lexical_subs';
use Carp           ();
use Encode::Locale ();    # Creates the 'locale' alias
use Encode 'resolve_alias';
use Exporter::Tidy _map => {
    run      => sub { run( undef, @_ ) },
    spawn    => sub { spawn( undef, @_ ) },
    syscmd   => sub { syscmd( undef, @_ ) },
    runsub   => sub { syscmd( undef, @_ )->runsub },
    spawnsub => sub { syscmd( undef, @_ )->spawnsub },
};

our $VERSION = '0.99.1';

### START Class::Inline ### v0.0.1 Fri Mar 28 14:23:37 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my @possible = ($CLASS);
        if ( defined &{"${CLASS}::DOES"} ) {
            push @possible, grep !/^${CLASS}$/, $CLASS->DOES('*');
        }
        my ( @new, @build );
        while (@possible) {
            no strict 'refs';
            my $c = shift @possible;
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            push @possible, @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("Sys::Cmd: unexpected argument '$_'") for keys %$attrs;
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    if ( my @missing = grep { not exists $_[0]->{$_} } 'cmd' ) {
        Carp::croak( 'Sys::Cmd required initial argument(s): '
              . join( ', ', @missing ) );
    }
    $_[0]{'cmd'} = eval { $_FIELDS->{'cmd'}->{'isa'}->( $_[0]{'cmd'} ) };
    Carp::confess( 'Sys::Cmd cmd: ' . $@ ) if $@;
    $_[0]{'dir'} = eval { $_FIELDS->{'dir'}->{'isa'}->( $_[0]{'dir'} ) }
      if exists $_[0]{'dir'};
    Carp::confess( 'Sys::Cmd dir: ' . $@ ) if $@;
    $_[0]{'encoding'} =
      eval { $_FIELDS->{'encoding'}->{'isa'}->( $_[0]{'encoding'} ) }
      if exists $_[0]{'encoding'};
    Carp::confess( 'Sys::Cmd encoding: ' . $@ ) if $@;
    $_[0]{'env'} = eval { $_FIELDS->{'env'}->{'isa'}->( $_[0]{'env'} ) }
      if exists $_[0]{'env'};
    Carp::confess( 'Sys::Cmd env: ' . $@ ) if $@;
    $_[0]{'mock'} = eval { $_FIELDS->{'mock'}->{'isa'}->( $_[0]{'mock'} ) }
      if exists $_[0]{'mock'};
    Carp::confess( 'Sys::Cmd mock: ' . $@ ) if $@;
    map { delete $_[1]->{$_} } 'cmd', 'dir', 'encoding', 'env', 'err', 'input',
      'mock', 'on_exit', 'out';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}
sub cmd { __RO() if @_ > 1; $_[0]{'cmd'} // undef }
sub dir { __RO() if @_ > 1; $_[0]{'dir'} // undef }

sub encoding {
    __RO() if @_ > 1;
    $_[0]{'encoding'} //= eval {
        $_FIELDS->{'encoding'}->{'isa'}->( $_FIELDS->{'encoding'}->{'default'} );
    };
    Carp::confess( 'invalid (Sys::Cmd::encoding) default: ' . $@ ) if $@;
    $_[0]{'encoding'};
}
sub env   { __RO() if @_ > 1; $_[0]{'env'}   // undef }
sub err   { __RO() if @_ > 1; $_[0]{'err'}   // undef }
sub input { __RO() if @_ > 1; $_[0]{'input'} // undef }

sub mock {
    if ( @_ > 1 ) {
        $_[0]{'mock'} = eval { $_FIELDS->{'mock'}->{'isa'}->( $_[1] ) };
        Carp::confess( 'invalid (Sys::Cmd::mock) value: ' . $@ ) if $@;
    }
    $_[0]{'mock'} // undef;
}

sub on_exit {
    if ( @_ > 1 ) { $_[0]{'on_exit'} = $_[1]; }
    $_[0]{'on_exit'} // undef;
}
sub out { __RO() if @_ > 1; $_[0]{'out'} // undef }

sub _dump {
    my $self = shift;
    my $x    = do {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Maxdepth = ( shift // 2 );
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper($self);
    };
    $x =~ s/.*?{/{/;
    $x =~ s/}.*?\n$/}/;
    my $i = 0;
    my @list;
    do {
        @list = caller( $i++ );
    } until $list[3] eq __PACKAGE__ . '::_dump';
    warn "$self $x at $list[1]:$list[2]\n";
}

@_CLASS = grep 1,### END Class::Inline ###
 {
    cmd => {
        isa => sub {
            ref $_[0] eq 'ARRAY' || _croak("cmd must be ARRAYREF");
            @{ $_[0] }           || _croak("Missing cmd elements");
            if ( grep { !defined $_ } @{ $_[0] } ) {
                _croak('cmd array cannot contain undef elements');
            }
            $_[0];
        },
        required => 1,
    },
    encoding => {
        default => 'locale',
        isa     => sub {
            my $e = resolve_alias( $_[0] )
              || _croak("Unknown Encoding: $_[0]");
            $e;
        },
    },
    env => {
        isa => sub {
            ref $_[0] eq 'HASH' || _croak("env must be HASHREF");
            $_[0];
        },
    },
    dir => {
        isa => sub {
            -d $_[0] || _croak("directory not found: $_[0]");
            $_[0];
        },
    },
    input => {},
    out   => {},
    err   => {},
    mock  => {
        is  => 'rw',
        isa => sub {
            ( ( not defined $_[0] ) || 'CODE' eq ref $_[0] )
              || _croak('must be CODEref');
            $_[0];
        },
    },
    on_exit => { is => 'rw', },
};

sub _croak {
    local $Carp::CarpInternal{'Sys::Cmd'}          = 1;
    local $Carp::CarpInternal{'Sys::Cmd::Process'} = 1;
    Carp::croak(@_);
}

my sub merge_args {
    my $template = shift;

    my ( @cmd, $opts );
    foreach my $arg (@_) {
        if ( ref($arg) eq 'HASH' ) {
            _croak( __PACKAGE__ . ': only a single hashref allowed' )
              if $opts;
            $opts = $arg;
        }
        else {
            push( @cmd, $arg );
        }
    }
    $opts //= {};

    if ($template) {
        $opts->{cmd} = [ $template->cmdline, @cmd ];
        if ( exists $opts->{env} ) {
            my %env = ( each %{ $template->env }, each %{ $opts->{env} } );
            $opts->{env} = \%env;
        }
        return { %$template, %$opts };
    }

    _croak('$cmd must be defined') unless @cmd && defined $cmd[0];

    if ( 'CODE' ne ref( $cmd[0] ) and not $opts->{mock} ) {
        delete $opts->{mock};
        require File::Spec;
        if ( File::Spec->splitdir( $cmd[0] ) == 1 ) {
            require File::Which;
            $cmd[0] = File::Which::which( $cmd[0] )
              || _croak( 'command not found: ' . $cmd[0] );
        }

        if ( !-x $cmd[0] ) {
            _croak( 'command not executable: ' . $cmd[0] );
        }
    }
    $opts->{cmd} = \@cmd;
    $opts;
}

sub cmdline {
    my $self = shift;
    if (wantarray) {
        return @{ $self->cmd };
    }
    else {
        return join( ' ', @{ $self->cmd } );
    }
}

sub run {
    my $self    = shift;
    my $opts    = merge_args( $self, @_ );
    my $ref_out = delete $opts->{out};
    my $ref_err = delete $opts->{err};
    my $proc    = Sys::Cmd::Process->new($opts);

    my @err = $proc->stderr->getlines;
    my @out = $proc->stdout->getlines;
    $proc->wait_child;

    if ( $proc->signal != 0 ) {
        _croak(
            sprintf(
                '%s[%d] %s [signal: %d core: %d]',
                join( '', @err ), $proc->pid, scalar $proc->cmdline,
                $proc->signal,    $proc->core
            )
        );
    }
    elsif ( $proc->exit != 0 ) {
        _croak(
            sprintf(
                '%s[%d] %s [exit: %d]',
                join( '', @err ),      $proc->pid,
                scalar $proc->cmdline, $proc->exit
            )
        );
    }

    if ($ref_err) {
        $$ref_err = join '', @err;
    }
    elsif (@err) {
        local @Carp::CARP_NOT = (__PACKAGE__);
        Carp::carp @err;
    }

    if ($ref_out) {
        $$ref_out = join '', @out;
    }
    elsif ( defined( my $wa = wantarray ) ) {
        return @out if $wa;
        return join( '', @out );
    }
}

sub spawn {
    my $self = shift;
    Sys::Cmd::Process->new( merge_args( $self, @_ ) );
}

sub syscmd {
    my $self = shift;
    Sys::Cmd->new( merge_args( $self, @_ ) );
}

sub runsub {
    my $self = shift;
    sub { $self->run(@_) };
}

sub spawnsub {
    my $self = shift;
    sub { $self->spawn(@_) };
}

package Sys::Cmd::Process;
our $VERSION = '0.99.1';
use parent -norequire, 'Sys::Cmd';
use Encode 'encode';
use IO::Handle;
use Log::Any qw/$log/;
### START Class::Inline ### v0.0.1 Fri Mar 28 14:23:37 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my @possible = ($CLASS);
        if ( defined &{"${CLASS}::DOES"} ) {
            push @possible, grep !/^${CLASS}$/, $CLASS->DOES('*');
        }
        my ( @new, @build );
        while (@possible) {
            no strict 'refs';
            my $c = shift @possible;
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            push @possible, @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("Sys::Cmd::Process: unexpected argument '$_'")
          for keys %$attrs;
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    map { delete $_[1]->{$_} } '_coderef';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub _coderef {
    __RO() if @_ > 1;
    $_[0]{'_coderef'} //= $_FIELDS->{'_coderef'}->{'default'}->( $_[0] );
}

sub core {
    if ( @_ > 1 ) { $_[0]{'core'} = $_[1]; }
    $_[0]{'core'} //= $_FIELDS->{'core'}->{'default'}->( $_[0] );
}

sub exit {
    if ( @_ > 1 ) { $_[0]{'exit'} = $_[1]; }
    $_[0]{'exit'} //= $_FIELDS->{'exit'}->{'default'}->( $_[0] );
}
sub has_exit { exists $_[0]{'exit'} }

sub pid {
    if ( @_ > 1 ) { $_[0]{'pid'} = $_[1]; }
    $_[0]{'pid'} // undef;
}

sub signal {
    if ( @_ > 1 ) { $_[0]{'signal'} = $_[1]; }
    $_[0]{'signal'} //= $_FIELDS->{'signal'}->{'default'}->( $_[0] );
}

sub stderr {
    if ( @_ > 1 ) { $_[0]{'stderr'} = $_[1]; }
    $_[0]{'stderr'} //= $_FIELDS->{'stderr'}->{'default'}->( $_[0] );
}

sub stdin {
    if ( @_ > 1 ) { $_[0]{'stdin'} = $_[1]; }
    $_[0]{'stdin'} //= $_FIELDS->{'stdin'}->{'default'}->( $_[0] );
}

sub stdout {
    if ( @_ > 1 ) { $_[0]{'stdout'} = $_[1]; }
    $_[0]{'stdout'} //= $_FIELDS->{'stdout'}->{'default'}->( $_[0] );
}

sub _dump {
    my $self = shift;
    my $x    = do {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Maxdepth = ( shift // 2 );
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper($self);
    };
    $x =~ s/.*?{/{/;
    $x =~ s/}.*?\n$/}/;
    my $i = 0;
    my @list;
    do {
        @list = caller( $i++ );
    } until $list[3] eq __PACKAGE__ . '::_dump';
    warn "$self $x at $list[1]:$list[2]\n";
}

@_CLASS = grep 1,### END Class::Inline ###
 {
    _coderef => {
        default => sub {
            my $c = $_[0]->cmd->[0];
            ref($c) eq 'CODE' ? $c : undef;
        },
    },
    pid => {
        is       => 'rw',
        init_arg => undef,
    },
    stdin => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    stdout => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    stderr => {
        is       => 'rw',
        init_arg => undef,
        default  => sub { IO::Handle->new },
    },
    exit => {
        is        => 'rw',
        init_arg  => undef,
        predicate => 1,
        default   => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
    signal => {
        is       => 'rw',
        init_arg => undef,
        default  => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
    core => {
        is       => 'rw',
        init_arg => undef,
        default  => sub {
            Sys::Cmd::_croak(
                'Process status values invalid before wait_child()');
        },
    },
};

sub _spawn {
    my $self = shift;
    require Proc::FastSpawn;

    # Get new handles to descriptors 0,1,2
    my $fd0 = IO::Handle->new_from_fd( 0, 'r' );
    my $fd1 = IO::Handle->new_from_fd( 1, 'w' );
    my $fd2 = IO::Handle->new_from_fd( 2, 'w' );

    # Backup the original 0,1,2 file descriptors
    open my $old_fd0, '<&', 0;
    open my $old_fd1, '>&', 1;
    open my $old_fd2, '>&', 2;

    # Pipe our filehandles to new child filehandles
    pipe( my $child_in,  $self->stdin )  || die "pipe: $!";
    pipe( $self->stdout, my $child_out ) || die "pipe: $!";
    pipe( $self->stderr, my $child_err ) || die "pipe: $!";

    # Make sure that 0,1,2 are inherited (probably are anyway)
    Proc::FastSpawn::fd_inherit( $_, 1 ) for 0, 1, 2;

    # But don't inherit the rest
    Proc::FastSpawn::fd_inherit( fileno($_), 0 )
      for $old_fd0, $old_fd1, $old_fd2, $child_in, $child_out, $child_err,
      $self->stdin, $self->stdout, $self->stderr;

    my $locale = $self->encoding;
    my $cmd_as_octets =
      [ map { encode( $locale => $_, Encode::FB_CROAK | Encode::LEAVE_SRC ) }
          @{ $self->cmd } ];

    eval {
        # Re-open 0,1,2 by duping the child pipe ends
        open $fd0, '<&', fileno($child_in);
        open $fd1, '>&', fileno($child_out);
        open $fd2, '>&', fileno($child_err);

        # Kick off the new process
        $self->pid(
            Proc::FastSpawn::spawn(
                $cmd_as_octets->[0],
                $cmd_as_octets,
                [
                    map { $_ . '=' . ( defined $ENV{$_} ? $ENV{$_} : '' ) }
                      keys %ENV
                ]
            )
        );

    };
    my $err = $@;

    # Restore our local 0,1,2 to the originals
    open $fd0, '<&', fileno($old_fd0);
    open $fd1, '>&', fileno($old_fd1);
    open $fd2, '>&', fileno($old_fd2);

    # Complain if the spawn failed for some reason
    Sys::Cmd::_croak($err) if $err;
    Sys::Cmd::_croak('Unable to spawn child') unless defined $self->pid;

    # Parent doesn't need to see the child or backup descriptors anymore
    close($_)
      for $old_fd0, $old_fd1, $old_fd2, $child_in, $child_out, $child_err;

    return;
}

sub _fork {
    my $self = shift;

    pipe( my $child_in,  $self->stdin )  || die "pipe: $!";
    pipe( $self->stdout, my $child_out ) || die "pipe: $!";
    pipe( $self->stderr, my $child_err ) || die "pipe: $!";

    $self->pid( fork() );
    if ( !defined $self->pid ) {
        my $why = $!;
        die "fork: $why";
    }

    if ( $self->pid > 0 ) {    # parent
        close $child_in;
        close $child_out;
        close $child_err;
        return;
    }

    # Child
    $self->exit(0);            # stop DESTROY() from trying to reap
    $child_err->autoflush(1);

    my $enc = ':encoding(' . $self->encoding . ')';

    foreach my $quad (
        [ \*STDIN,  '<&=', fileno($child_in),  0 ],
        [ \*STDOUT, '>&=', fileno($child_out), 1 ],
        [ \*STDERR, '>&=', fileno($child_err), 1 ]
      )
    {
        my ( $fh, $mode, $fileno, $autoflush ) = @$quad;

        open( $fh, $mode, $fileno )
          or print $child_err sprintf "[%d] open %s, %s: %s\n", $self->pid,
          $fh, $mode, $!;

        binmode $fh, $enc;
        $fh->autoflush(1) if $autoflush;
    }

    close $self->stdin;
    close $self->stdout;
    close $self->stderr;
    close $child_in;
    close $child_out;
    close $child_err;

    if ( my $code = $self->_coderef ) {
        $code->();
        _exit(0);
    }

    exec( @{ $self->cmd } );
    die "exec: $!";
}

sub BUILD {
    my $self = shift;

    Carp::carp '"out" attribute ignored' if defined $self->out;
    Carp::carp '"err" attribute ignored' if defined $self->err;

    if ( my $mock = $self->mock ) {
        my $ref = $mock->($self);
        my $out = shift @$ref // '';
        my $err = shift @$ref // '';
        open my $outfd, '<', \$out || die "open \$out: $!";
        open my $errfd, '<', \$err || die "open \$err: $!";
        $self->pid( -$$ );
        $self->stdout($outfd);
        $self->stderr($errfd);
        $self->mock( sub { $ref } );
        $log->debugf(
            '[%d] %s [%s]',        $self->pid,
            scalar $self->cmdline, $self->encoding
        );
        return;
    }

    my $dir = $self->dir;
    require File::chdir if $dir;

    no warnings 'once';
    local $File::chdir::CWD = $dir if $dir;
    use warnings 'once';

    local %ENV = %ENV;

    if ( defined( my $x = $self->env ) ) {
        my $locale = $self->encoding;
        while ( my ( $key, $val ) = each %$x ) {
            my $keybytes = encode( $locale, $key, Encode::FB_CROAK );
            if ( defined $val ) {
                $ENV{$keybytes} = encode( $locale, $val, Encode::FB_CROAK );
            }
            else {
                delete $ENV{$keybytes};
            }
        }
    }

    $self->_coderef ? $self->_fork : $self->_spawn;
    $self->stdin->autoflush(1);

    my $enc = ':encoding(' . $self->encoding . ')';
    binmode( $self->stdin,  $enc ) or warn "binmode stdin: $!";
    binmode( $self->stdout, $enc ) or warn "binmode stdout: $!";
    binmode( $self->stderr, $enc ) or warn "binmode stderr: $!";

    $log->debugf( '[%d] %s [%s]', $self->pid, scalar $self->cmdline, $enc );

    # some input was provided
    if ( defined( my $input = $self->input ) ) {
        local $SIG{PIPE} =
          sub { warn "Broken pipe when writing to:" . $self->cmdline };

        if ( 'ARRAY' eq ref $input && @$input ) {
            $self->stdin->print(@$input);
        }
        elsif ( length $input ) {
            $self->stdin->print($input);
        }

        $self->stdin->close;
    }

    return;
}

sub close {
    my $self = shift;

    foreach my $h (qw/stdin stdout stderr/) {

        # may not be defined during global destruction
        my $fh = $self->$h or next;
        $fh->opened        or next;
        if ( $h eq 'stderr' ) {
            warn sprintf( '[%d] uncollected stderr: %s', $self->pid // -1, $_ )
              for $self->stderr->getlines;
        }
        $fh->close || Carp::carp "error closing $h: $!";
    }

    return;
}

sub wait_child {
    my $self = shift;
    my $pid  = $self->pid // return;
    return $self->exit if $self->has_exit;

    if ( $self->mock ) {
        my ( $exit, $signal, $core ) = @{ $self->mock->() };
        $self->exit( $exit     // 0 );
        $self->signal( $signal // 0 );
        $self->core( $core     // 0 );
    }
    elsif ( $pid > 0 ) {

        local $?;
        local $!;

        my $pid = waitpid $self->pid, 0;
        my $ret = $?;

        if ( $pid != $self->pid ) {
            warn
              sprintf( 'Could not reap child process %d (waitpid returned: %d)',
                $self->pid, $pid );
            $ret = 0;
        }

        if ( $ret == -1 ) {

            # So waitpid returned a PID but then sets $? to this
            # strange value? (Strange in that tests randomly show it to
            # be invalid.) Most likely a perl bug; I think that waitpid
            # got interrupted and when it restarts/resumes the status
            # is lost.
            #
            # See http://www.perlmonks.org/?node_id=641620 for a
            # possibly related discussion.
            #
            # However, since I localised $? and $! above I haven't seen
            # this problem again, so I hope that is a good enough work
            # around. Lets warn any way so that we know when something
            # dodgy is going on.
            warn __PACKAGE__
              . ' received invalid child exit status for pid '
              . $self->pid
              . ' Setting to 0';
            $ret = 0;

        }

        $self->exit( $ret >> 8 );
        $self->signal( $ret & 127 );
        $self->core( $ret & 128 );
    }

    # $pid <= 0, so... bad execution by spawn
    else {
        $self->exit(-1);
        $self->signal(0);
        $self->core(0);
    }

    if ( $self->signal != 0 ) {
        $log->infof(
            '[%d] %s [signal: %d core: %d]',
            $self->pid,    scalar $self->cmdline,
            $self->signal, $self->core
        );
    }
    else {
        $log->infof(
            '[%d] %s [exit: %d]',  $self->pid,
            scalar $self->cmdline, $self->exit,
        );
    }

    if ( my $subref = $self->on_exit ) {
        $subref->($self);
    }

    $self->exit;
}

sub DESTROY {
    my $self = shift;
    $self->close;
    $self->wait_child;
}

1;

__END__

=head1 NAME

Sys::Cmd - run a system command or spawn a system processes

=head1 VERSION

0.99.1 (2025-03-28)

=head1 SYNOPSIS

    use Sys::Cmd qw/run spawn/;

    # Simplest scenario:
    #   - returns standard output
    #   - warns about standard error
    #   - raises exception on failure
    $output = run(@cmd);

    # Alternative input / output:
    #  - returns standard output lines
    #  - after feeding its standard input
    @output = run( @cmd, { input => 'food' } );

    # More flexibility:
    #  - Run in alternative directory
    #  - With a modified environment
    #  - Capturing stdout/stderr into variables
    run(
        @cmd,
        {
            dir      => '/',
            env => { SECRET => $pass },
            out => \$out,
            err => \$err,
        }
    );

    # Spawn a process for asynchronous interaction
    #  - Caller responsible for exec path, all input & output
    #  - No exception raised on non-zero exit
    $proc = spawn( @cmd, { encoding => 'iso-8859-3' },);

    while ( my $line = $proc->stdout->getline ) {
        $proc->stdin->print("thanks\n");
    }

    my @errors = $proc->stderr->getlines;

    $proc->close();         # Finished talking to file handles
    $proc->wait_child();    # Cleanup

    # read process termination information
    $proc->exit();          # exit status
    $proc->signal();        # signal
    $proc->core();          # core dumped? (boolean)

=head1 DESCRIPTION

B<Sys::Cmd> lets you run system commands and capture their output, or
spawn and interact with a system process through its C<STDIN>,
C<STDOUT>, and C<STDERR> file handles.

It also provides mock process support, where the caller defines their
own outputs and error values.  L<Log::Any> is used for logging.

The following functions are exported on demand:

=over 4

=item run( @cmd, [\%opt] ) => $output | @output

Execute C<@cmd> and return what the command sends to its C<STDOUT>,
raising an exception in the event of non-zero exit value. In array
context returns a list of lines instead of a scalar string.

The first element of C<@cmd> determines what/how things are run:

=over

=item * If it has a path component (absolute or relative) it is
executed as is, using L<Proc::Spawn>.

=item * If it is a CODE reference (subroutine) then the funtion forks
before running it in a child process. Unsupported on Win32.

=item * Everything else is looked up using L<File::Which> and the
result is executed with L<Proc::Spawn>.

=back

The optional C<\%opts> hashref lets you modify the execution via the
following configuration keys (=> default):

=over

=item dir => $PWD

The working directory the command will be run in. Note that if C<@cmd>
is a relative path, it may not be found from the new location.

=item encoding => $Encode::Locale::ENCODING_LOCALE

A string value identifying the encoding that applies to input/output
file-handles, command arguments, and environment variables.  Defaults
to the 'locale' alias from L<Encode::Locale>.

=item env

A hashref containing key/values to be added to the current environment
at run-time. If a key has an undefined value then the key is removed
from the environment altogether.

=item input

A scalar (string), or ARRAY reference, which is fed to the command via
its standard input, which is then closed.  An empty value ('') or empty
list will close the command's standard input without printing. An
undefined value (the default) leaves the handle open.

Some commands close their standard input on startup, which causes a
SIGPIPE when trying to write to it, for which B<Sys::Cmd> will warn.

=item mock

A subroutine reference which runs instead of the actual command, which
provides the fake outputs and exit values. See L</"MOCKING"> below for
details.

=item out

A reference to a scalar which is populated with output. When used,
C<run()> returns nothing.

=item err

A reference to a scalar which is populated with error output. When
used, C<run()> does not warn of errors.

=item on_exit

A subref to be called at the time that process termination is detected.

=back

=item spawn( @cmd, [\%opt] ) => Sys::Cmd::Process

Executes C<@cmd>, similarly to C<run()> above, but without any input
handling, output collection, or process waiting; the C<\%opt> keys
C<input>, C<out> and C<err> keys are I<invalid> for this function.

This returns a (Sys::Cmd::Process) object representing the running
process, which has the following methods:

=over

=item cmdline() => @list | $str

In array context returns a list of the command and its arguments.  In
scalar context returns a string of the command and its arguments joined
together by spaces.

=item close()

Close all filehandles to the child process. Note that file handles will
automaticaly be closed when the B<Sys::Cmd> object is destroyed.
Annoyingly, this means that in the following example C<$fh> will be
closed when you tried to use it:

    my $fh = Sys::Cmd->new( %args )->stdout;

So you have to keep track of the Sys::Cmd object manually.

=item pid()

The command's process ID.

=item stderr()

The command's I<STDERR> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item stdin()

The command's I<STDIN> file handle, based on L<IO::Handle> so you can
call print() etc methods on it. Autoflush is automatically enabled on
this handle.

=item stdout()

The command's I<STDOUT> file handle, based on L<IO::Handle> so you can
call getline() etc methods on it.

=item wait_child() -> $exit_value

Wait for the child to exit using
L<waitpid|http://perldoc.perl.org/functions/waitpid.html>, collect the
exit status and return it. This method sets the I<exit>, I<signal> and
I<core> attributes and is called automatically when the
B<Sys::Cmd::Process> object is destroyed.

=back

After C<wait_child> has been called the following are also valid:

=over

=item core()

A boolean indicating the process core was dumped.

=item exit()

The command's exit value, shifted by 8 (see "perldoc -f system").

=item signal()

The signal number (if any) that terminated the command, bitwise-added
with 127 (see "perldoc -f system").

=back

=item syscmd( @cmd, [\%opt] ) => Sys::Cmd

When calling a command multiple times, possibly with different
arguments or environments, a kind of "templating" mechanism can be
useful, to avoid repeatedly specifying configuration values and wearing
a path lookup penalty each call.

A B<Sys::Cmd> object represents a command (or coderef) I<to be>
executed, which you can create with the C<syscmd> function:

    my $git  = syscmd('git',
        env => {
            GIT_AUTHOR_NAME  => 'Geekette',
            GIT_AUTHOR_EMAIL => 'xyz@example.com',
        }
    );

You can then repeatedly call C<run()> or C<spawn()> I<methods> on the
object for the actual work. The methods work the same way in terms of
input, output, and return values as the exported package functions.
However, additional arguments and options are I<merged>:

    my @list = $git->run('ls-files');    # $PWD
    my $commit = $git->run( 'commit', {
        env => { GIT_AUTHOR_NAME => 'Sysgeek' }
    });

For even less syntax you can use the C<runsub> or C<spawnsub> methods
to get a subroutine you can call directly:

    my $git    = syscmd('git')->runsub;
    my @list   = $git->('ls-files');
    my $commit = $git->('show');

=item runsub( @cmd, [\%opt] ) => CODEref

Equivalent to manually calling C<syscmd(...)> followed by the C<runsub>
method.

    #!perl
    use Sys::Cmd 'runsub';
    my $ls = runsub('ls');
    $ls->('here');
    $ls->('there');

=item spawnsub( @cmd, [\%opt] ) => CODEref

Equivalent to manually calling C<syscmd(...)> followed by the
C<spawnsub> method.

    #!perl
    use Sys::Cmd 'spawnsub';
    my $spawn = spawnsub('command');
    foreach my $i (0..9) {
        my $proc = $spawn->('arg', $i);
        $proc->stdin->print("Hello\n");
        print $proc->stdout->getlines;
        $proc->wait_child
    }

=back

=head1 MOCKING (EXPERIMENTAL!)

The C<mock> subroutine, when given, runs instead of the command line
process. It is passed the B<Sys::Cmd::Process> object as its first
argument, which gives it access to the cmdline, dir, env, encoding,
attributes as methods.

    run(
        'junk',
        {
            input => 'food',
            mock  => sub {
                my $proc  = shift;
                my $input = shift;
                [ $proc->cmdline . ":Thanks for $input!\n", '', 0 ];
            }
        }
    );

It is required to return an ARRAY reference (possibly empty), with the
following elements:

    [
        "standard output\n",    # default ''
        "standard error\n",     # default ''
        $exit,                  # default 0
        $signal,                # default 0
        $core,                  # default 0
    ]

Those values are then returned from C<run> as usual. At present this
feature is not useful for interactive (i.e. spawned) use, as it does
not dynamically respond to calls to C<$proc->stdin->print()>.

Note that this interface is B<EXPERIMENTAL> and subject to change!
Don't use it anywhere you can't deal with breakage!

=head1 ALTERNATIVES

L<AnyEvent::Run>, L<AnyEvent::Util>, L<Argv>, L<Capture::Tiny>,
L<Child>, L<Forks::Super>, L<IO::Pipe>, L<IPC::Capture>, L<IPC::Cmd>,
L<IPC::Command::Multiplex>, L<IPC::Exe>, L<IPC::Open3>,
L<IPC::Open3::Simple>, L<IPC::Run>, L<IPC::Run3>,
L<IPC::RunSession::Simple>, L<IPC::ShellCmd>, L<IPC::System::Simple>,
L<POE::Pipe::TwoWay>, L<Proc::Background>, L<Proc::Fork>,
L<Proc::Spawn>, L<Spawn::Safe>, L<System::Command>

=head1 SUPPORT

This distribution is managed via github:

    https://github.com/mlawren/p5-Sys-Cmd

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence E<lt>mark@rekudos.netE<gt>, based heavily on
L<Git::Repository::Command> by Philippe Bruhat (BooK).

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2025 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

