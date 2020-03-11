package Pcore v0.122.1;

use v5.30;
no strict qw[refs];    ## no critic qw[TestingAndDebugging::ProhibitProlongedStrictureOverride]
use common::header;
use Pcore::Core::Exporter qw[];
use Pcore::Core::Const qw[:CORE];

# define %EXPORT_PRAGMA for exporter
our $EXPORT_PRAGMA = {
    ansi     => undef,    # export ANSI color variables
    class    => undef,    # package is a Moo class
    const    => undef,    # export "const" keyword
    dist     => undef,    # mark package aas Pcore dist main module
    embedded => undef,    # run in embedded mode
    export   => undef,    # install standart import method
    forktmpl => undef,    # run fork template on startup
    l10n     => undef,    # register package L10N domain
    res      => undef,    # export Pcore::Util::Result qw[res]
    role     => undef,    # package is a Moo role
    sql      => undef,    # export Pcore::Handle::DBI::Const qw[:TYPES]
};

our $EMBEDDED    = 0;       # Pcore::Core used in embedded mode
our $SCRIPT_PATH = $0;
our $WIN_ENC     = undef;
our $CON_ENC     = undef;

# define alias for export
our $P = sub : const {'Pcore'};

# configure standard library
our $UTIL = {
    handle => 'Pcore::Handle',
    html   => 'Pcore::Util::HTML',
    http   => 'Pcore::HTTP',
    mime   => 'Pcore::Util::MIME',
    uri    => 'Pcore::Util::URI',
    uuid   => 'Pcore::Util::UUID',
};

sub import {
    my $self = shift;

    # get caller
    my $caller = caller;

    # parse tags and pragmas
    my $import = Pcore::Core::Exporter::parse_import( $self, @_ );

    state $INIT = do {

        # store -embedded pragma
        $EMBEDDED = 1 if $import->{pragma}->{embedded};

        require B::Hooks::AtRuntime;
        require B::Hooks::EndOfScope::XS;
        require EV;
        require AnyEvent;
        require Coro;
        require Pcore::Core::Patch::Coro;
        require Pcore::Core::OOP::Class;
        require Pcore::Core::OOP::Role;

        $Coro::POOL_SIZE = 256;

        # install run-time hook to caller package
        B::Hooks::AtRuntime::at_runtime( \&Pcore::_CORE_RUN );

        _CORE_INIT($import);

        1;
    };

    # export header
    common::header->import;

    # export P sub to avoid indirect calls
    *{"$caller\::P"} = $P;

    # re-export core packages
    Pcore::Core::Const->import( -caller => $caller );

    # process -l10n pragma
    if ( $import->{pragma}->{l10n} ) {
        require Pcore::Core::L10N;

        Pcore::Core::L10N->import( -caller => $caller );
    }

    # export "dump"
    Pcore::Core::Dump->import( -caller => $caller );

    # process -export pragma
    Pcore::Core::Exporter->import( -caller => $caller ) if $import->{pragma}->{export};

    # process -dist pragma
    $ENV->register_dist($caller) if $import->{pragma}->{dist};

    # process -const pragma
    if ( $import->{pragma}->{const} ) {
        *{"$caller\::const"} = \&Const::Fast::const;
    }

    # process -ansi pragma
    if ( $import->{pragma}->{ansi} ) {
        Pcore::Core::Const->import( -caller => $caller, qw[:ANSI] );
    }

    # import exceptions
    Pcore::Core::Exception->import( -caller => $caller );

    # process -res pragma
    if ( $import->{pragma}->{res} ) {
        require Pcore::Util::Result;

        Pcore::Util::Result->import( -caller => $caller, qw[res] );
    }

    # process -sql pragma
    if ( $import->{pragma}->{sql} ) {
        require Pcore::Handle::DBI::Const;

        Pcore::Handle::DBI::Const->import( -caller => $caller, qw[:TYPES :QUERY :SQL_VALUES_IDX] );
    }

    # re-export OOP
    if ( $import->{pragma}->{class} ) {
        Pcore::Core::OOP::Class->import($caller);
    }
    elsif ( $import->{pragma}->{role} ) {
        Pcore::Core::OOP::Role->import($caller);
    }

    return;
}

sub _CORE_INIT ($import) {
    require Pcore::Core::Dump;
    Pcore::Core::Dump->import(':CORE');

    # set default fallback mode for all further :encoding I/O layers
    $PerlIO::encoding::fallback = Encode::FB_CROAK() | Encode::STOP_AT_PARTIAL();

    if ($MSWIN) {
        require Win32;
        require Win32::Console::ANSI;

        $WIN_ENC = 'cp' . Win32::GetACP();
        $CON_ENC = Win32::GetConsoleCP();

        if ($CON_ENC) {
            $CON_ENC = 'cp' . $CON_ENC;

            # check if we can properly decode STDIN under MSWIN
            eval {
                Encode::perlio_ok($CON_ENC) or die;

                1;
            } || do {
                say qq[FATAL: Console input encoding "$CON_ENC" isn't supported. Use chcp to change console codepage.];

                exit 1;
            };
        }
        else {
            $CON_ENC = undef;
        }
    }
    else {
        $CON_ENC = 'UTF-8';
        $WIN_ENC = 'UTF-8';
    }

    # decode @ARGV
    for (@ARGV) {
        $_ = Encode::decode( $WIN_ENC, $_, Encode::FB_CROAK() );
    }

    # configure run-time environment
    require Pcore::Core::Env;

    # STDIN
    if ( -t *STDIN ) {    ## no critic qw[InputOutput::ProhibitInteractiveTest]
        if ($MSWIN) {
            binmode *STDIN, ":raw:crlf:encoding($CON_ENC)" or die;
        }
        else {
            binmode *STDIN, ':raw:encoding(UTF-8)' or die;
        }
    }
    else {
        binmode *STDIN, ':raw' or die;
    }

    # STDOUT
    config_stdout(*STDOUT);
    config_stdout(*STDERR);

    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    require Pcore::Core::Exception;    # set $SIG{__DIE__}, $SIG{__WARN__}, $SIG->{INT}, $SIG->{TERM} handlers

    # process -forktmpl pragma
    require Pcore::Util::Sys::ForkTmpl if !$MSWIN && $import->{pragma}->{forktmpl};

    _CORE_INIT_AFTER_FORK();

    return;
}

sub _CORE_INIT_AFTER_FORK {
    require Pcore::Core::Patch::AnyEvent;

    return;
}

# TODO add PerlIO::removeEsc layer
sub config_stdout ($h) {
    if ($MSWIN) {
        if ( -t $h ) {    ## no critic qw[InputOutput::ProhibitInteractiveTest]
            require Pcore::Core::PerlIOviaWinUniCon;

            binmode $h, ':raw:via(Pcore::Core::PerlIOviaWinUniCon)' or die;    # terminal
        }
        else {
            binmode $h, ':raw:encoding(UTF-8)' or die;                         # file TODO +RemoveESC
        }
    }
    else {
        if ( -t $h ) {                                                         ## no critic qw[InputOutput::ProhibitInteractiveTest]
            binmode $h, ':raw:encoding(UTF-8)' or die;                         # terminal
        }
        else {
            binmode $h, ':raw:encoding(UTF-8)' or die;                         # file TODO +RemoveESC
        }
    }

    return;
}

sub _CORE_RUN {

    # EMBEDDED mode, if run not from INIT block or -embedded pragma specified:
    # CLI not parsed / processed;
    # process permissions not changed;
    # process will not daemonized;

    if ( !$EMBEDDED ) {
        require Pcore::Core::CLI;

        Pcore::Core::CLI->new( { class => 'main' } )->run( \@ARGV );

        if ( !$MSWIN ) {

            # GID is inherited from UID by default
            if ( defined $ENV->{UID} && !defined $ENV->{GID} ) {
                my $uid = $ENV->{UID} =~ /\A\d+\z/sm ? $ENV->{UID} : getpwnam $ENV->{UID};

                die qq[Can't find uid "$ENV->{UID}"] if !defined $uid;

                $ENV->{GID} = [ getpwuid $uid ]->[2];
            }

            # change priv
            Pcore->sys->change_priv( gid => $ENV->{GID}, uid => $ENV->{UID} );

            P->sys->daemonize if $ENV->{DAEMONIZE};
        }
    }

    return;
}

# L10N
sub set_locale ( $self, $locale = undef ) {
    require Pcore::Core::L10N;

    return Pcore::Core::L10N::set_locale($locale);
}

# AUTOLOAD
sub AUTOLOAD ( $self, @ ) {    ## no critic qw[ClassHierarchies::ProhibitAutoloading]
    my $lib = lc our $AUTOLOAD =~ s/\A.*:://smr;

    my $class = $UTIL->{$lib} // 'Pcore::Util::' . ucfirst $lib;

    require $class =~ s[::][/]smgr . '.pm';

    if ( $class->can('new') ) {
        eval <<"PERL";         ## no critic qw[BuiltinFunctions::ProhibitStringyEval ErrorHandling::RequireCheckingReturnValueOfEval]
            *{$lib} = sub {
                shift;

                return $class->new(\@_);
            };
PERL
    }
    else {

        # create lib namespace with AUTOLOAD method
        eval <<"PERL";         ## no critic qw[BuiltinFunctions::ProhibitStringyEval ErrorHandling::RequireCheckingReturnValueOfEval]
            package $self\::Util::_$lib;

            use Pcore;

            sub AUTOLOAD {
                my \$method = our \$AUTOLOAD =~ s/\\A.*:://smr;

                # install method wrapper
                eval <<"EVAL";
                    *{"$self\::Util::_$lib\::\$method"} = sub {
                        shift;

                        return &$class\::\$method;
                    };
EVAL

                goto &{\$method};
            }
PERL

        # create lib namespace access method
        *{$lib} = sub : const {"$self\::Util::_$lib"};
    }

    goto &{$lib};
}

# EVENT
sub ev ($self) {
    state $broker = do {
        require Pcore::Core::Event;

        my $_broker = Pcore::Core::Event->new;

        # set default log channels
        $_broker->bind_events( 'log.EXCEPTION.*', 'stderr:' );

        # file logs are disabled by default for scripts, that are not part of the distribution
        if ( $ENV->dist ) {
            $_broker->bind_events( 'log.EXCEPTION.FATAL', 'file:fatal.log' );
            $_broker->bind_events( 'log.EXCEPTION.ERROR', 'file:error.log' );
            $_broker->bind_events( 'log.EXCEPTION.WARN',  'file:warn.log' );
        }

        $_broker;
    };

    return $broker;
}

sub get_listener ( $self, $id ) {
    return $self->ev->get_listener($id);
}

sub bind_events ( $self, $bindings, $listener ) {
    return $self->ev->bind_events( $bindings, $listener );
}

sub has_bindings ( $self, $key ) {
    return $self->ev->has_bindings($key);
}

sub forward_event ( $self, $ev ) {
    $self->ev->forward_event($ev);

    return;
}

sub fire_event ( $self, $key, $data = undef ) {
    my $ev = {
        key  => $key,
        data => $data,
    };

    return $self->ev->forward_event($ev);
}

sub sendlog ( $self, $key, $title, $data = undef ) {
    my $broker = $self->ev;

    return if !$broker->has_bindings("log.$key");

    my $ev;

    ( $ev->{channel}, $ev->{level} ) = split /[.]/sm, $key, 2;

    die q[Log level must be specified] unless $ev->{level};

    $ev->{key}       = "log.$key";
    $ev->{timestamp} = Time::HiRes::time();
    \$ev->{title} = \$title;
    \$ev->{data}  = \$data;

    $broker->forward_event($ev);

    return;
}

# CV
*cv = *P::cv = sub ( $self, $cb = undef ) {
    require Pcore::Core::CV;

    return bless [$cb], 'Pcore::Core::CV';
};

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "common" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 68                   | Variables::ProtectPrivateVars - Private variable used                                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 157, 186, 189, 193,  | ErrorHandling::RequireCarping - "die" used instead of "croak"                                                  |
## |      | 225, 228, 233, 236,  |                                                                                                                |
## |      | 261, 390             |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 243                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_CORE_RUN' declared but not used    |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 161                  | InputOutput::RequireCheckedSyscalls - Return value of flagged function ignored - say                           |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore - perl applications development environment

=begin HTML

<p><a href="https://metacpan.org/pod/Pcore" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/Pcore.svg"></a></p>

=end HTML

=head1 SYNOPSIS

    use Pcore -<pragma> qw[<import>], {config};

=head1 DESCRIPTION

Documentation will be provided later.

=head1 ENVIRONMENT

=over

=item * WORKSPACE

=back

=cut
